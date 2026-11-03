import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/branding/brand_mark.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/core/utils/amount_input.dart';
import 'package:gexpenses/core/utils/currency_formatter.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/balance_providers.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

class SetBalanceScreen extends ConsumerStatefulWidget {
  const SetBalanceScreen({super.key});

  @override
  ConsumerState<SetBalanceScreen> createState() => _SetBalanceScreenState();
}

class _SetBalanceScreenState extends ConsumerState<SetBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = parseAmountInput(_amountController.text) ?? 0;
      final balanceRepo = ref.read(balanceRepositoryProvider);
      await balanceRepo.setInitialBalance(amount);
      ref.invalidate(hasBalanceProvider);
      ref.invalidate(currentBalanceProvider);
      ref.invalidate(initialBalanceProvider);
    } catch (e) {
      debugPrint('Saving initial balance failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Lets the user start with a zero balance instead of forcing an amount.
  Future<void> _onSkip() async {
    try {
      final balanceRepo = ref.read(balanceRepositoryProvider);
      await balanceRepo.setInitialBalance(0);
      ref.invalidate(hasBalanceProvider);
      ref.invalidate(currentBalanceProvider);
      ref.invalidate(initialBalanceProvider);
    } catch (e) {
      debugPrint('Skipping initial balance failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient color wash behind the form.
            Positioned(
              top: -90,
              right: -70,
              child: _Halo(
                size: 240,
                color: colorScheme.primary.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _Halo(
                size: 220,
                color: colorScheme.tertiary.withValues(alpha: 0.08),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(
                  AppConstants.spacing24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.formMaxWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FadeSlideIn(
                          offset: 24,
                          child: BrandMark(size: 104),
                        ),
                        const SizedBox(height: AppConstants.spacing24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: Text(
                            l10n.welcomeMessage,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacing8),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: Text(
                            l10n.welcomeSubtitle,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacing32),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: Container(
                            padding: const EdgeInsetsDirectional.all(
                              AppConstants.spacing20,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusLarge,
                              ),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.enterInitialBalance,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppConstants.spacing16),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [AmountInputFormatter()],
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: l10n.enterAmount,
                                    prefixText: '${CurrencyFormatter.symbol} ',
                                    prefixStyle: textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                    hintStyle: textTheme.headlineMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.25),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.amountRequired;
                                    }
                                    final amount = parseAmountInput(value);
                                    if (amount == null || amount < 0) {
                                      return l10n.invalidAmount;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppConstants.spacing20),
                                SizedBox(
                                  height: 54,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _onSubmit,
                                    child: AnimatedSwitcher(
                                      duration: AppMotion.fast,
                                      child: _isLoading
                                          ? SizedBox(
                                              key: const ValueKey('loading'),
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : Text(
                                              l10n.getStarted,
                                              key: const ValueKey('label'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacing4),
                                TextButton(
                                  onPressed: _isLoading ? null : _onSkip,
                                  child: Text(l10n.skipForNow),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
