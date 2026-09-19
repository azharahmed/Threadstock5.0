import 'dart:ui';

/// Centralized service and constants for desktop window dimensions on Windows & macOS.
class DesktopWindowService {
  DesktopWindowService._();

  /// Minimum supported desktop window width (px).
  static const double minWidth = 1100.0;

  /// Minimum supported desktop window height (px).
  static const double minHeight = 720.0;

  /// Default initial desktop window width (px).
  static const double defaultWidth = 1440.0;

  /// Default initial desktop window height (px).
  static const double defaultHeight = 900.0;

  /// Minimum window size as a [Size] object.
  static const Size minSize = Size(minWidth, minHeight);

  /// Default initial window size as a [Size] object.
  static const Size defaultSize = Size(defaultWidth, defaultHeight);
}
