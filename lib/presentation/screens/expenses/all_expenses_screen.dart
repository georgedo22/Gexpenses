import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/core/theme/app_motion.dart';
import 'package:gexpenses/core/utils/app_layout.dart';
import 'package:gexpenses/domain/enums/expense_category.dart';
import 'package:gexpenses/l10n/app_localizations.dart';
import 'package:gexpenses/presentation/providers/expense_providers.dart';
import 'package:gexpenses/presentation/widgets/empty_state_widget.dart';
import 'package:gexpenses/presentation/widgets/expense_tile.dart';
import 'package:gexpenses/presentation/widgets/loading_skeleton.dart';
import 'package:gexpenses/presentation/widgets/motion_widgets.dart';

/// Full expense history with search, category filtering and paging.
class AllExpensesScreen extends ConsumerStatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  ConsumerState<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends ConsumerState<AllExpensesScreen> {
  static const int _pageSize = 50;

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  ExpenseCategory? _category;
  int _limit = _pageSize;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _limit = _pageSize;
      });
    });
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _limit = _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final filter = ExpenseFilter(
      query: _query,
      category: _category,
      limit: _limit,
    );
    final expensesAsync = ref.watch(filteredExpensesProvider(filter));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.allExpenses)),
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppConstants.spacing16,
                  AppConstants.spacing8,
                  AppConstants.spacing16,
                  AppConstants.spacing8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchExpenses,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.clearFilters,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _clearFilters,
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppConstants.spacing16,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppConstants.spacing8,
                      ),
                      child: ChoiceChip(
                        label: Text(l10n.allCategories),
                        selected: _category == null,
                        onSelected: (_) => setState(() {
                          _category = null;
                          _limit = _pageSize;
                        }),
                      ),
                    ),
                    for (final category in ExpenseCategory.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppConstants.spacing8,
                        ),
                        child: ChoiceChip(
                          avatar: Icon(
                            category.icon,
                            size: 16,
                            color: category.color,
                          ),
                          label: Text(l10n.categoryName(category)),
                          selected: _category == category,
                          onSelected: (selected) => setState(() {
                            _category = selected ? category : null;
                            _limit = _pageSize;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacing8),
              Expanded(
                child: expensesAsync.when(
                  loading: () => const LoadingSkeleton(itemCount: 6),
                  error: (error, _) => EmptyStateWidget(
                    icon: Icons.cloud_off_rounded,
                    title: l10n.errorTitle,
                    subtitle: l10n.errorGeneric,
                    action: TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(filteredExpensesProvider(filter)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  ),
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      final hasFilters = _query.isNotEmpty || _category != null;
                      return EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: hasFilters
                            ? l10n.noResults
                            : l10n.noExpensesTitle,
                        subtitle: hasFilters
                            ? l10n.noResultsSubtitle
                            : l10n.noExpensesSubtitle,
                        action: hasFilters
                            ? TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.filter_alt_off_rounded),
                                label: Text(l10n.clearFilters),
                              )
                            : null,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppConstants.spacing16,
                        0,
                        AppConstants.spacing16,
                        AppConstants.spacing24,
                      ),
                      itemCount: expenses.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppConstants.spacing8),
                      itemBuilder: (context, index) {
                        if (index == expenses.length) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppConstants.spacing8,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${expenses.length} ${l10n.expenseCount}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                if (expenses.length >= _limit)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      top: AppConstants.spacing8,
                                    ),
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          setState(() => _limit += _pageSize),
                                      icon: const Icon(
                                        Icons.expand_more_rounded,
                                      ),
                                      label: Text(l10n.loadMore),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }

                        return FadeSlideIn(
                          delay: AppMotion.stagger(index, step: 20),
                          offset: 10,
                          child: ExpenseTile(expense: expenses[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
