import 'package:flutter/material.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';

/// A gently pulsing placeholder shown while a list is loading.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.itemCount = 4, this.itemHeight = 76});

  final int itemCount;
  final double itemHeight;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.35,
      upperBound: 0.75,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!AppMotion.reduced(context)) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final reduceMotion = AppMotion.reduced(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = reduceMotion ? 0.15 : _controller.value;
        return Column(
          children: [
            for (var i = 0; i < widget.itemCount; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppConstants.spacing8,
                ),
                child: Container(
                  height: widget.itemHeight,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: opacity * 0.25),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
