/// Centralized breakpoint system for ThreadStock desktop layouts (Windows & macOS).
class AppBreakpoints {
  AppBreakpoints._();

  /// Minimum supported desktop window width.
  static const double minWindowWidth = 1100.0;

  /// Minimum supported desktop window height.
  static const double minWindowHeight = 720.0;

  /// Compact desktop: 1100 – 1279 px.
  static const double compactDesktop = 1100.0;

  /// Standard desktop: 1280 – 1599 px.
  static const double desktop = 1280.0;

  /// Large desktop: 1600+ px.
  static const double largeDesktop = 1600.0;

  /// Maximum content constraint to prevent endless horizontal stretching.
  static const double maxContentWidth = 1440.0;
}
