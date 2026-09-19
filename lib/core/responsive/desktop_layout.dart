import 'package:flutter/material.dart';
import 'app_breakpoints.dart';
import 'responsive_values.dart';

/// Wraps page content to enforce maximum desktop content width (~1440 px),
/// horizontal centering on wide monitors, and responsive horizontal margins.
class DesktopContentConstraint extends StatelessWidget {
  const DesktopContentConstraint({
    super.key,
    required this.child,
    this.verticalPadding = 24.0,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  final Widget child;
  final double verticalPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final hMargin = context.responsiveHorizontalMargin;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hMargin,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
