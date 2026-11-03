import 'package:flutter/material.dart';

/// Breakpoints and shared measurements used to keep screens responsive.
class AppLayout {
  AppLayout._();

  static const double compactWidth = 600;
  static const double railBreakpoint = 900;
  static const double contentMaxWidth = 720;
  static const double wideContentMaxWidth = 820;
  static const double formMaxWidth = 520;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) =>
      widthOf(context) < compactWidth;

  /// Wide layouts trade the bottom bar for a navigation rail.
  static bool useNavigationRail(BuildContext context) =>
      widthOf(context) >= railBreakpoint;

  static EdgeInsetsDirectional pagePadding(BuildContext context) =>
      EdgeInsetsDirectional.symmetric(
        horizontal: isCompact(context) ? 16 : 28,
        vertical: 12,
      );

  static int columnsFor(BuildContext context, {int compact = 3, int wide = 4}) =>
      isCompact(context) ? compact : wide;
}

/// Centers [child] and caps its width so content stays readable on tablets
/// and foldables instead of stretching edge to edge.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
