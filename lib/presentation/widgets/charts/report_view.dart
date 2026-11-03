import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/loading_skeleton.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

/// Shared padding for report list content.
EdgeInsetsGeometry reportContentPadding(BuildContext context) =>
    AppLayout.pagePadding(
      context,
    ).add(const EdgeInsetsDirectional.only(top: 8, bottom: 24));

/// Handles loading, empty and loaded states for every report period.
///
/// Consuming an `AsyncValue` (instead of a Future created in `build`) means
/// unrelated rebuilds never re-fetch the report.
class ReportAsyncView<T> extends StatelessWidget {
  const ReportAsyncView({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T report) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // skipLoadingOnRefresh keeps stale data visible while a background
    // refresh runs, instead of flashing the skeleton.
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => ListView(
        padding: reportContentPadding(context),
        children: const [LoadingSkeleton(itemCount: 3, itemHeight: 96)],
      ),
      error: (error, _) => EmptyStateWidget(
        icon: Icons.cloud_off_rounded,
        title: l10n.errorTitle,
        subtitle: l10n.errorGeneric,
        action: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
        ),
      ),
      data: (report) => FadeSlideIn(child: builder(context, report)),
    );
  }
}
