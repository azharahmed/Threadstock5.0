import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/services/greeting_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/overview/data/dashboard_repository.dart';
import 'package:threadstock/features/overview/presentation/helpers/date_time_greeting_helper.dart';
import 'package:threadstock/features/overview/presentation/pages/overview_page.dart';
import 'package:threadstock/features/overview/presentation/widgets/live_dashboard_header.dart';
import 'package:threadstock/features/overview/presentation/widgets/live_date_time_text.dart';

class _TestDashboardRepository extends DashboardRepository {
  final DashboardData mockData;
  _TestDashboardRepository(this.mockData);

  @override
  Future<DashboardData> fetchDashboardData({String? businessId}) async {
    return mockData;
  }
}

void main() {
  setUp(() {
    DateTimeGreetingHelper.testNowOverride = null;
    CurrentBusinessService.instance.setCurrentBusiness(
      Business(
        id: 'biz_launchgrid',
        ownerUserId: 'user_123',
        legalName: 'LaunchGrid',
        businessType: 'Retail Fashion',
        countryCode: 'IND',
        currencyCode: 'INR',
        locationRange: 'single',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() {
    DateTimeGreetingHelper.testNowOverride = null;
  });

  group('THREADSTOCK TIME-AWARE GREETING RULES', () {
    test('10:55 PM shows Good night', () {
      final nightTime = DateTime(2026, 9, 28, 22, 55);
      expect(DateTimeGreetingHelper.getGreetingWord(nightTime), 'Good night');
      expect(
        DateTimeGreetingHelper.formatGreeting(
          userName: 'Azhar Ahmed',
          dateTime: nightTime,
        ),
        'Good night, Azhar Ahmed 👋',
      );
    });

    test('8:00 AM & 8:30 AM shows Good morning', () {
      final morningTime = DateTime(2026, 9, 28, 8, 30);
      expect(DateTimeGreetingHelper.getGreetingWord(morningTime), 'Good morning');
      expect(
        DateTimeGreetingHelper.formatGreeting(
          userName: 'Azhar Ahmed',
          dateTime: morningTime,
        ),
        'Good morning, Azhar Ahmed 👋',
      );
    });

    test('2:00 PM shows Good afternoon', () {
      final afternoonTime = DateTime(2026, 9, 28, 14, 0);
      expect(DateTimeGreetingHelper.getGreetingWord(afternoonTime), 'Good afternoon');
      expect(
        DateTimeGreetingHelper.formatGreeting(
          userName: 'Azhar Ahmed',
          dateTime: afternoonTime,
        ),
        'Good afternoon, Azhar Ahmed 👋',
      );
    });

    test('7:30 PM shows Good evening', () {
      final eveningTime = DateTime(2026, 9, 28, 19, 30);
      expect(DateTimeGreetingHelper.getGreetingWord(eveningTime), 'Good evening');
      expect(
        DateTimeGreetingHelper.formatGreeting(
          userName: 'Azhar Ahmed',
          dateTime: eveningTime,
        ),
        'Good evening, Azhar Ahmed 👋',
      );
    });

    test('Boundary test: 5:00 AM starts Good morning', () {
      final t5am = DateTime(2026, 9, 28, 5, 0);
      expect(DateTimeGreetingHelper.getGreetingWord(t5am), 'Good morning');
    });

    test('Boundary test: 11:59 AM is Good morning, 12:00 PM starts Good afternoon', () {
      final t1159am = DateTime(2026, 9, 28, 11, 59);
      final t12pm = DateTime(2026, 9, 28, 12, 0);
      expect(DateTimeGreetingHelper.getGreetingWord(t1159am), 'Good morning');
      expect(DateTimeGreetingHelper.getGreetingWord(t12pm), 'Good afternoon');
    });

    test('Boundary test: 4:59 PM is Good afternoon, 5:00 PM starts Good evening', () {
      final t459pm = DateTime(2026, 9, 28, 16, 59);
      final t5pm = DateTime(2026, 9, 28, 17, 0);
      expect(DateTimeGreetingHelper.getGreetingWord(t459pm), 'Good afternoon');
      expect(DateTimeGreetingHelper.getGreetingWord(t5pm), 'Good evening');
    });

    test('Boundary test: 8:59 PM is Good evening, 9:00 PM starts Good night', () {
      final t859pm = DateTime(2026, 9, 28, 20, 59);
      final t9pm = DateTime(2026, 9, 28, 21, 0);
      expect(DateTimeGreetingHelper.getGreetingWord(t859pm), 'Good evening');
      expect(DateTimeGreetingHelper.getGreetingWord(t9pm), 'Good night');
    });

    test('Boundary test: 4:59 AM is Good night', () {
      final t459am = DateTime(2026, 9, 28, 4, 59);
      expect(DateTimeGreetingHelper.getGreetingWord(t459am), 'Good night');
    });

    test('Greeting without username falls back to time-appropriate greeting word', () {
      final nightTime = DateTime(2026, 9, 28, 22, 0);
      expect(
        DateTimeGreetingHelper.formatGreeting(userName: null, dateTime: nightTime),
        'Good night 👋',
      );
      expect(
        DateTimeGreetingHelper.formatGreeting(userName: '', dateTime: nightTime, includeWave: false),
        'Good night',
      );
    });

    test('GreetingService delegates cleanly to DateTimeGreetingHelper', () {
      final morningTime = DateTime(2026, 9, 28, 9, 0);
      expect(GreetingService.getGreetingWord(morningTime), 'Good morning');
      expect(
        GreetingService.formatGreeting(userName: 'Azhar', dateTime: morningTime),
        'Good morning, Azhar 👋',
      );
    });
  });

  group('THREADSTOCK DATE AND TIME FORMATTING & TIMEZONE', () {
    test('Formats Sunday, 28 Sep 2026 • 10:55 PM cleanly', () {
      final dt = DateTime(2026, 9, 28, 22, 55);
      final formatted = DateTimeGreetingHelper.formatDateTime(dt);
      expect(formatted, 'Monday, 28 Sep 2026 • 10:55 PM');
    });

    test('Formats short format 28 Sep 2026 • 10:55 PM cleanly', () {
      final dt = DateTime(2026, 9, 28, 22, 55);
      final formatted = DateTimeGreetingHelper.formatDateTimeShort(dt);
      expect(formatted, '28 Sep 2026 • 10:55 PM');
    });

    test('Timezone parsing: parses GMT/UTC offsets and names correctly', () {
      expect(
        DateTimeGreetingHelper.parseTimezoneOffset('IST (GMT+5:30)'),
        const Duration(hours: 5, minutes: 30),
      );
      expect(
        DateTimeGreetingHelper.parseTimezoneOffset('UTC+02:00'),
        const Duration(hours: 2),
      );
      expect(
        DateTimeGreetingHelper.parseTimezoneOffset('GMT-5'),
        const Duration(hours: -5),
      );
      expect(
        DateTimeGreetingHelper.parseTimezoneOffset('GST (Dubai)'),
        const Duration(hours: 4),
      );
    });

    test('Timezone application: shifts UTC by location offset', () {
      final baseUtc = DateTime.utc(2026, 9, 28, 17, 25); // 5:25 PM UTC
      // With IST (+5:30), should be 22:55 (10:55 PM)
      final istTime = DateTimeGreetingHelper.nowInTimezone(
        locationOffset: const Duration(hours: 5, minutes: 30),
        baseUtc: baseUtc,
      );
      expect(istTime.hour, 22);
      expect(istTime.minute, 55);
      expect(DateTimeGreetingHelper.getGreetingWord(istTime), 'Good night');
    });

    test('Timezone application: falls back safely to local device time when offset is null', () {
      final local = DateTimeGreetingHelper.nowInTimezone();
      expect(local, isNotNull);
    });
  });

  group('LIVE DATE/TIME & HEADER WIDGET TESTS', () {
    testWidgets('LiveDateTimeText renders clock icon and formatted date-time', (tester) async {
      final fixedTime = DateTime(2026, 9, 28, 22, 55);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDateTimeText(
              customNow: fixedTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
      expect(find.text('Monday, 28 Sep 2026 • 10:55 PM'), findsOneWidget);
    });

    testWidgets('LiveDashboardHeader renders time-aware greeting and live date-time at 10:55 PM', (tester) async {
      final nightTime = DateTime(2026, 9, 28, 22, 55);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDashboardHeader(
              userName: 'Azhar Ahmed',
              businessName: 'LaunchGrid',
              locationName: 'FCD (JHB)',
              isFreshMode: false,
              customNow: nightTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Greeting
      expect(find.text('Good night, Azhar Ahmed 👋'), findsOneWidget);
      // Date & time
      expect(find.text('Monday, 28 Sep 2026 • 10:55 PM'), findsOneWidget);
      // Operational update subtitle
      expect(find.text('Here is your operational update for FCD (JHB).'), findsOneWidget);
    });

    testWidgets('LiveDashboardHeader renders morning greeting at 8:30 AM', (tester) async {
      final morningTime = DateTime(2026, 9, 28, 8, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDashboardHeader(
              userName: 'Azhar Ahmed',
              businessName: 'LaunchGrid',
              isFreshMode: true,
              customNow: morningTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning, Azhar Ahmed 👋'), findsOneWidget);
      expect(find.text('Monday, 28 Sep 2026 • 8:30 AM'), findsOneWidget);
      expect(find.textContaining('LaunchGrid is ready.'), findsOneWidget);
    });

    testWidgets('OverviewPage displays time-aware greeting and visible date/time at night', (tester) async {
      DateTimeGreetingHelper.testNowOverride = DateTime(2026, 9, 28, 22, 55);

      const data = DashboardData(
        userName: 'Azhar Ahmed',
        locationName: 'fcd',
        currencySymbol: '₹',
        todaySalesCents: 0,
        totalStockCount: 0,
        lowStockCount: 0,
        completedSalesCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(
              dashboardRepository: _TestDashboardRepository(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At 10:55 PM, it shows Good night (NOT Good morning)
      expect(find.text('Good night, Azhar Ahmed 👋'), findsOneWidget);
      expect(find.text('Good morning, Azhar Ahmed 👋'), findsNothing);

      // Visible date and time
      expect(find.text('Monday, 28 Sep 2026 • 10:55 PM'), findsOneWidget);

      // Fresh hero subtitle
      expect(find.textContaining('LaunchGrid is ready.'), findsOneWidget);
    });
  });
}
