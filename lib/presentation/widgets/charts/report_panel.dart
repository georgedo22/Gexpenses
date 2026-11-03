import 'package:flutter/material.dart';
import 'package:gexpenses/core/constants/app_constants.dart';

/// Rounded surface used for charts and secondary report content.
class ReportPanel extends StatelessWidget {
  const ReportPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}
