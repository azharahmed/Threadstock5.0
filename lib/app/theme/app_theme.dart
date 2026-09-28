import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThreadStockTheme {
  static const Color ivory = Color(0xFFF6F1EA);
  static const Color stone = Color(0xFFE6DDCF);
  static const Color champagne = Color(0xFFC7A76B);
  static const Color graphite = Color(0xFF1F1D1A);
  static const Color graphiteSoft = Color(0xFF2D2925);
  static const Color cocoa = Color(0xFF6B4D2D);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: champagne,
      brightness: Brightness.light,
      primary: champagne,
      secondary: cocoa,
      surface: ivory,
      onSurface: graphite,
    );

    final baseText = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ivory,
      appBarTheme: const AppBarTheme(
        backgroundColor: ivory,
        foregroundColor: graphite,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE7DFC7), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: champagne.withValues(alpha: 0.16),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: graphite),
        ),
      ),
      textTheme: baseText.copyWith(
        headlineLarge: GoogleFonts.cormorantGaramond(
          color: graphite,
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          color: graphite,
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.cormorantGaramond(
          color: graphite,
          fontSize: 23,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.cormorantGaramond(
          color: graphite,
          fontSize: 21,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.inter(
          color: graphite,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: graphite,
          fontSize: 16.5,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: graphite,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          color: const Color(0xFF6B6358),
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.inter(
          color: graphite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.inter(
          color: graphite,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.inter(
          color: const Color(0xFF8E867B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: champagne,
      brightness: Brightness.dark,
      primary: champagne,
      secondary: stone,
      surface: const Color(0xFF12100E),
      onSurface: const Color(0xFFF5F0EA),
    );

    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF12100E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF12100E),
        foregroundColor: Color(0xFFF5F0EA),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B1916),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF3A352F), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF181614),
        indicatorColor: champagne.withValues(alpha: 0.20),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      textTheme: baseText.copyWith(
        headlineLarge: GoogleFonts.cormorantGaramond(
          color: const Color(0xFFF5F0EA),
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          color: const Color(0xFFF5F0EA),
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.cormorantGaramond(
          color: const Color(0xFFF5F0EA),
          fontSize: 23,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.cormorantGaramond(
          color: const Color(0xFFF5F0EA),
          fontSize: 21,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.inter(
          color: const Color(0xFFF5F0EA),
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: const Color(0xFFF5F0EA),
          fontSize: 16.5,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFFF5F0EA),
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          color: const Color(0xFF8A8275),
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.inter(
          color: const Color(0xFFF5F0EA),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.inter(
          color: const Color(0xFFF5F0EA),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.inter(
          color: const Color(0xFF8A8275),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================
  // CANONICAL TYPOGRAPHY SPECIFICATION HELPERS
  // ==========================================

  /// Overview top title: Cormorant Garamond 500, 32 px
  static TextStyle pageTitle([Color? color]) => GoogleFonts.cormorantGaramond(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: color ?? graphite,
  );

  /// Good morning, Alex: Cormorant Garamond 500, 44–48 px
  static TextStyle heroGreeting([Color? color]) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 46,
        fontWeight: FontWeight.w500,
        color: color ?? graphite,
        letterSpacing: -0.4,
      );

  /// Greeting subtitle: Inter 400, 16–18 px
  static TextStyle greetingSubtitle([Color? color]) => GoogleFonts.inter(
    fontSize: 16.5,
    fontWeight: FontWeight.w400,
    color: color ?? const Color(0xFF635D54),
  );

  /// AI briefing label: Inter 600, 12–13 px
  static TextStyle aiBriefingLabel([Color? color]) => GoogleFonts.inter(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    color: color ?? const Color(0xFFB38850),
  );

  /// AI briefing headline: Cormorant Garamond 500, 24–26 px
  static TextStyle aiBriefingHeadline([Color? color]) =>
      GoogleFonts.cormorantGaramond(
        fontSize: 25,
        fontWeight: FontWeight.w500,
        color: color ?? const Color(0xFF181513),
        height: 1.25,
      );

  /// AI briefing description: Inter 400, 14–15 px
  static TextStyle aiBriefingDesc([Color? color]) => GoogleFonts.inter(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color ?? const Color(0xFF5C554B),
  );

  /// Buttons: Inter 600, 14 px
  static TextStyle buttonText([Color? color]) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
  );

  /// KPI labels: Inter 400–500, 13–14 px
  static TextStyle kpiLabel([Color? color]) => GoogleFonts.inter(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: color ?? const Color(0xFF635D54),
  );

  /// KPI values: Cormorant Garamond Bold, 36 px
  static TextStyle kpiValue([Color? color]) => GoogleFonts.cormorantGaramond(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: color ?? const Color(0xFF161412),
  );

  /// Card headings — “Needs Attention”: Cormorant Garamond 500, 22–24 px
  static TextStyle cardHeading([Color? color]) => GoogleFonts.cormorantGaramond(
    fontSize: 23,
    fontWeight: FontWeight.w500,
    color: color ?? const Color(0xFF181513),
  );

  /// Product names: Inter 600, 14–15 px
  static TextStyle productName([Color? color]) => GoogleFonts.inter(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: color ?? const Color(0xFF1E1C1A),
  );

  /// Product metadata: Inter 400, 12–13 px
  static TextStyle productMetadata([Color? color]) => GoogleFonts.inter(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: color ?? const Color(0xFF6B6358),
  );

  /// Status pills: Inter 500–600, 12 px
  static TextStyle statusPill([Color? color]) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: color ?? graphite,
  );

  /// Chart title: Cormorant Garamond 500, 20–22 px
  static TextStyle chartTitle([Color? color]) => GoogleFonts.cormorantGaramond(
    fontSize: 21,
    fontWeight: FontWeight.w500,
    color: color ?? const Color(0xFF181513),
  );

  /// Chart labels: Inter 400, 11–12 px
  static TextStyle chartLabel([Color? color]) => GoogleFonts.inter(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: color ?? const Color(0xFF8A8275),
  );

  /// Sidebar menu: Inter 400–500, 14–15 px
  static TextStyle sidebarMenu({bool isSelected = false}) => GoogleFonts.inter(
    fontSize: 14.5,
    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
    color: isSelected ? const Color(0xFF1E1C1A) : const Color(0xFF4C453C),
  );

  /// Sidebar section labels: Inter 600, 11 px
  static TextStyle sidebarSectionLabel([Color? color]) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    color: color ?? const Color(0xFF8E867B),
  );

  /// User name: Inter 600, 14 px
  static TextStyle userName([Color? color]) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color ?? const Color(0xFF1E1C1A),
  );

  /// User role: Inter 400, 12 px
  static TextStyle userRole([Color? color]) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? const Color(0xFF7E766B),
  );

  /// Primary button luxury gradient: dark charcoal → warm brown
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF171717),
      Color(0xFF1D1B19),
      Color(0xFF30271F),
      Color(0xFF423225),
    ],
    stops: [0.0, 0.45, 0.75, 1.0],
  );

  /// Primary button arrow champagne-gold color
  static const Color buttonArrowGold = Color(0xFFD3A75F);
}
