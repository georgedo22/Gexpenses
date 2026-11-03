import 'package:flutter/material.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/l10n/app_localizations.dart';

/// Previous / next navigation for a report period, with a tappable label
/// that can jump straight to a date.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.onLabelTap,
    this.canGoNext = true,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Tapping the period label (e.g. to open a date picker).
  final VoidCallback? onLabelTap;

  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: AppConstants.spacing8,
      ),
      child: Row(
        children: [
          // arrow_back/forward mirror automatically in RTL layouts.
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: l10n.previous,
            style: IconButton.styleFrom(
              minimumSize: const Size(
                AppConstants.minTouchTarget,
                AppConstants.minTouchTarget,
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.resolve(context, AppMotion.fast),
              switchInCurve: AppMotion.emphasized,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: TextButton(
                key: ValueKey(label),
                onPressed: onLabelTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppConstants.spacing8,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            tooltip: l10n.next,
            style: IconButton.styleFrom(
              minimumSize: const Size(
                AppConstants.minTouchTarget,
                AppConstants.minTouchTarget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
