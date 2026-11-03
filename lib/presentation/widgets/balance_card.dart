import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_colors.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/widgets/animated_amount.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final currentBalanceAsync = ref.watch(currentBalanceProvider);
    final initialBalanceAsync = ref.watch(initialBalanceProvider);
    final isLow = ref.watch(isLowBalanceProvider).valueOrNull ?? false;

    final List<Color> gradient;
    if (isLow) {
      gradient = AppColors.balanceGradientWarning;
    } else if (brightness == Brightness.dark) {
      gradient = AppColors.balanceGradientDark;
    } else {
      gradient = AppColors.balanceGradientLight;
    }

    return AnimatedContainer(
      duration: AppMotion.resolve(context, AppMotion.slow),
      curve: AppMotion.emphasized,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        gradient: LinearGradient(
          colors: gradient,
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Stack(
          children: [
            // Soft light blooms add depth without any image assets.
            Positioned(
              top: -70,
              right: -50,
              child: _Glow(size: 180, opacity: 0.10),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: _Glow(size: 160, opacity: 0.07),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(
                AppConstants.spacing24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.currentBalance,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: AppMotion.resolve(context, AppMotion.medium),
                        switchInCurve: AppMotion.emphasized,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1)
                                .animate(animation),
                            child: child,
                          ),
                        ),
                        child: isLow
                            ? _LowBalanceBadge(label: l10n.lowBalance)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  currentBalanceAsync.when(
                    data: (balance) => Semantics(
                      label:
                          '${l10n.currentBalance}: '
                          '${CurrencyFormatter.format(balance)}',
                      excludeSemantics: true,
                      child: AnimatedAmount(
                        value: balance,
                        countFromZero: true,
                        style: textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    loading: () => SizedBox(
                      height: 40,
                      width: 160,
                      child: LinearProgressIndicator(
                        color: Colors.white.withValues(alpha: 0.4),
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    error: (_, _) => Text(
                      '---',
                      style: textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing12),
                  initialBalanceAsync.when(
                    data: (initialBalance) => Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: AppConstants.spacing4),
                        Flexible(
                          child: Text(
                            '${l10n.initialBalance}: '
                            '${CurrencyFormatter.format(initialBalance)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _LowBalanceBadge extends StatelessWidget {
  const _LowBalanceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
