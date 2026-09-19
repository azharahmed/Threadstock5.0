import 'package:flutter/widgets.dart';
import 'app_breakpoints.dart';

/// Context extensions and utilities for ThreadStock desktop responsive design.
extension DesktopResponsiveX on BuildContext {
  /// The current viewport size.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Current viewport width.
  double get screenWidth => screenSize.width;

  /// Current viewport height.
  double get screenHeight => screenSize.height;

  /// True if window width is in the compact desktop tier (1100–1279 px).
  bool get isCompactDesktop => screenWidth < AppBreakpoints.desktop;

  /// True if window width is in standard desktop tier (1280–1599 px).
  bool get isStandardDesktop =>
      screenWidth >= AppBreakpoints.desktop &&
      screenWidth < AppBreakpoints.largeDesktop;

  /// True if window width is in large desktop tier (1600+ px).
  bool get isLargeDesktop => screenWidth >= AppBreakpoints.largeDesktop;

  /// Suggested horizontal page margin based on screen width:
  /// - 1100–1279 px: 26 px
  /// - 1280–1599 px: 36 px
  /// - 1600+ px: 52 px
  double get responsiveHorizontalMargin {
    if (screenWidth < AppBreakpoints.desktop) {
      return 26.0;
    } else if (screenWidth < AppBreakpoints.largeDesktop) {
      return 36.0;
    } else {
      return 52.0;
    }
  }

  /// Responsive sidebar width:
  /// - Compact desktop: 220 px (luxury proportion without text crowding)
  /// - Standard/Large desktop: 240 px
  double get responsiveSidebarWidth {
    if (screenWidth < AppBreakpoints.desktop) {
      return 220.0;
    }
    return 240.0;
  }
}
