import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gexpenses/core/constants/app_constants.dart';
import 'package:gexpenses/data/database/database_helper.dart';
import 'package:gexpenses/data/repositories/balance_repository.dart';

/// Shared database helper singleton.
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepository(ref.watch(databaseHelperProvider));
});

/// Whether the user has completed onboarding (set an initial balance).
final hasBalanceProvider = FutureProvider<bool>((ref) async {
  return ref.watch(balanceRepositoryProvider).hasBalance();
});

final initialBalanceProvider = FutureProvider<double>((ref) async {
  return ref.watch(balanceRepositoryProvider).getInitialBalance();
});

final currentBalanceProvider = FutureProvider<double>((ref) async {
  return ref.watch(balanceRepositoryProvider).getCurrentBalance();
});

/// Whether the current balance has dropped below
/// [AppConstants.lowBalanceThreshold] of the initial balance.
final isLowBalanceProvider = FutureProvider<bool>((ref) async {
  final current = await ref.watch(currentBalanceProvider.future);
  final initial = await ref.watch(initialBalanceProvider.future);
  if (initial <= 0) return false;
  return current <= initial * AppConstants.lowBalanceThreshold;
});
