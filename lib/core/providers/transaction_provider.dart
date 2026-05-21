import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

// Which month the user is currently viewing
final selectedMonthProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

// Transactions for the selected month — auto-updates when month changes
final monthlyTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) {
  final d = ref.watch(selectedMonthProvider);
  return DatabaseHelper.instance.byMonth(d.year, d.month);
});

// Category spending totals — for pie chart
final categoryTotalsProvider =
    FutureProvider<Map<String, double>>((ref) {
  final d = ref.watch(selectedMonthProvider);
  return DatabaseHelper.instance.categoryTotals(d.year, d.month);
});

// Total income for selected month
final monthlyIncomeProvider = FutureProvider<double>((ref) {
  final d = ref.watch(selectedMonthProvider);
  return DatabaseHelper.instance.income(d.year, d.month);
});

// Total spending for selected month
final monthlySpentProvider = FutureProvider<double>((ref) {
  final d = ref.watch(selectedMonthProvider);
  return DatabaseHelper.instance.spent(d.year, d.month);
});

// 6-month trend data — for bar chart
final trend6Provider =
    FutureProvider<List<Map<String, dynamic>>>(
        (_) => DatabaseHelper.instance.trend6Months());

// Call this after adding/deleting transactions to refresh all screens
void refreshAll(WidgetRef ref) {
  ref.invalidate(monthlyTransactionsProvider);
  ref.invalidate(categoryTotalsProvider);
  ref.invalidate(monthlyIncomeProvider);
  ref.invalidate(monthlySpentProvider);
  ref.invalidate(trend6Provider);
}gtr