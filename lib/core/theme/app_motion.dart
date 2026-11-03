import 'package:flutter/material.dart';

/// Central motion system for the app.
///
/// Keeping durations, curves, and the shared page transition in one place keeps
/// the interface consistent, and every helper collapses to an instant state
/// when the platform asks for reduced motion.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration entrance = Duration(milliseconds: 520);
  static const Duration countUp = Duration(milliseconds: 700);

  /// Material 3 "emphasized" curve – quick to start, gentle to settle.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standard = Curves.easeOutCubic;

  /// Whether the operating system asked to minimise animation.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Resolves [duration] to [Duration.zero] when motion is reduced.
  static Duration resolve(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// Delay for the item at [index] in a staggered entrance.
  static Duration stagger(int index, {int step = 45, int maxItems = 8}) =>
      Duration(milliseconds: step * index.clamp(0, maxItems));
}

/// Standard fade + slide transition used for every pushed route.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context) || route.isFirst) return child;
    return _fadeSlideIn(context, animation, child);
  }
}

Widget _fadeSlideIn(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.emphasized,
    reverseCurve: Curves.easeInCubic,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
