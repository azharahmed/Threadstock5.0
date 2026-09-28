import 'package:flutter/material.dart';

/// A robust image rendering widget for ThreadStock that handles:
/// - Supabase Storage / remote URLs (`https://...` or `http://...`)
/// - Local Flutter assets (`Assets/...`)
/// - Graceful empty and error fallbacks
class SafeImage extends StatelessWidget {
  const SafeImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackColor = const Color(0xFFF1F5F9),
    this.iconColor = const Color(0xFF94A3B8),
    this.fallback,
  });

  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final Color iconColor;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final src = source?.trim();

    Widget placeholder() {
      if (fallback != null) return fallback!;
      return Container(
        width: width,
        height: height,
        color: fallbackColor,
        alignment: Alignment.center,
        child: Icon(
          fallbackIcon,
          size: (width != null && height != null)
              ? (width! < height! ? width! * 0.45 : height! * 0.45).clamp(16.0, 48.0)
              : 24,
          color: iconColor,
        ),
      );
    }

    if (src == null || src.isEmpty) {
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: placeholder())
          : placeholder();
    }

    Widget imageWidget;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      imageWidget = Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      );
    } else {
      imageWidget = Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }
}
