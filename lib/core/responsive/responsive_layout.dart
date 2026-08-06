import 'package:flutter/material.dart';

/// Breakpoint constants for responsive design (in logical pixels)
const double mobileBreakpoint = 600.0;
const double tabletBreakpoint = 1024.0;
const double desktopBreakpoint = 1440.0;

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
);

/// A widget that renders different layouts based on screen width.
///
/// - If screen width < [mobileBreakpoint] (600px), [mobile] layout is used.
/// - If screen width is between [mobileBreakpoint] and [tabletBreakpoint] (600px - 1023px),
///   [tablet] layout is used if provided, falling back to [mobile].
/// - If screen width >= [tabletBreakpoint] (1024px+), [desktop] layout is used if provided,
///   falling back to [tablet] or [mobile].
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder? tablet;
  final ResponsiveWidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint) {
          if (desktop != null) {
            return desktop!(context, constraints);
          }
          if (tablet != null) {
            return tablet!(context, constraints);
          }
          return mobile(context, constraints);
        }

        if (constraints.maxWidth >= mobileBreakpoint) {
          if (tablet != null) {
            return tablet!(context, constraints);
          }
          return mobile(context, constraints);
        }

        return mobile(context, constraints);
      },
    );
  }
}

/// Convenience extensions on [BuildContext] for responsive checks.
extension ResponsiveContextExtension on BuildContext {
  /// Whether the screen width is mobile size (< 600px).
  bool get isMobile => MediaQuery.sizeOf(this).width < mobileBreakpoint;

  /// Whether the screen width is tablet size (>= 600px and < 1024px).
  bool get isTablet {
    final width = MediaQuery.sizeOf(this).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Whether the screen width is desktop size (>= 1024px).
  bool get isDesktop => MediaQuery.sizeOf(this).width >= tabletBreakpoint;

  /// Whether the screen width is wide desktop size (> 1440px).
  bool get isWideDesktop => MediaQuery.sizeOf(this).width > desktopBreakpoint;
}
