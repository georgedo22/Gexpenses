import 'package:flutter/material.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';

/// A currency value that counts up to [value] whenever it changes.
///
/// Long amounts shrink to fit instead of overflowing on narrow phones or when
/// the user increases the system text scale.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.countUp,
    this.textAlign,
    this.countFromZero = false,
  });

  final double value;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  /// When true the number counts up from zero on its very first frame.
  final bool countFromZero;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: countFromZero ? 0 : value, end: value),
      duration: AppMotion.resolve(context, duration),
      curve: AppMotion.emphasized,
      builder: (context, animatedValue, _) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: textAlign == TextAlign.center
              ? Alignment.center
              : AlignmentDirectional.centerStart,
          child: Text(
            CurrencyFormatter.format(animatedValue),
            style: style,
            maxLines: 1,
            textAlign: textAlign,
            softWrap: false,
          ),
        );
      },
    );
  }
}
