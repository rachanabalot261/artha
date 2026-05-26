import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sms_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedMonthProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final spent = ref.watch(monthlySpentProvider);
    final cats = ref.watch(categoryTotalsProvider);
    final trend = ref.watch(trend6Provider);
    final now = DateTime.now();
    final isCurrentMonth =
        sel.month == now.month && sel.year == now.year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artha'),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => ref
                    .read(selectedMonthProvider.notifier)
                    .state =
                    DateTime(sel.year, sel.month - 1),
              ),
              GestureDetector(
                onTap: () => ref
                    .read(selectedMonthProvider.notifier)
                    .state = DateTime.now(),
                child: Text(
                  DateFormat('MMM yy').format(sel),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCurrentMonth
                        ? AppColors.purple
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    size: 20,
                    color: isCurrentMonth
                        ? AppColors.textMuted
                        : AppColors.textSecondary),
                onPressed: isCurrentMonth
                    ? null
                    : () => ref
                        .read(selectedMonthProvider.notifier)
                        .state =
                        DateTime(sel.year, sel.month + 1),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshAll(ref),
        color: AppColors.purple,
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          children: [
            // Income / Spent / Saved summary cards
            income.when(
              data: (inc) => spent.when(
                data: (sp) => _SummaryRow(
                    income: inc, spent: sp, saved: inc - sp),
                loading: () => const _SummaryLoading(),
                error: (_, __) => const SizedBox(),
              ),
              loading: () => const _SummaryLoading(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 16),

            // Category breakdown card
            cats.when(
              data: (data) => data.isEmpty
                  ? _EmptyState(
                      onImport: () async {
                        final count = await SmsService
                            .instance
                            .importInbox();
                        refreshAll(ref);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text(count > 0
                                ? '✓ $count transactions imported'
                                : 'No new transactions found'),
                            backgroundColor: count > 0
                                ? AppColors.income
                                : AppColors.expense,
                          ));
                        }
                      },
                    )
                  : _CategoryCard(totals: data),
              loading: () => const _CardSkeleton(height: 280),
              error: (e, _) => Text('$e'),
            ),

            const SizedBox(height: 12),

            // 6-month trend chart
            trend.when(
              data: (data) => _TrendCard(data: data),
              loading: () => const _CardSkeleton(height: 180),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income, spent, saved;
  const _SummaryRow(
      {required this.income,
      required this.spent,
      required this.saved});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryTile(
            label: 'Income',
            amount: income,
            color: AppColors.income,
            icon: Icons.south_west_rounded),
        const SizedBox(width: 10),
        _SummaryTile(
            label: 'Spent',
            amount: spent,
            color: AppColors.expense,
            icon: Icons.north_east_rounded),
        const SizedBox(width: 10),
        _SummaryTile(
            label: 'Saved',
            amount: saved,
            color: AppColors.saving,
            icon: Icons.savings_outlined),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _SummaryTile(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 8),
            Text(
              '₹${_fmt(amount.abs())}',
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Smart formatting: 150000 → 1.5L, 5000 → 5K
  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          3,
          (_) => Expanded(
                child: Container(
                  height: 80,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, double> totals;
  const _CategoryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final total = totals.values.fold(0.0, (a, b) => a + b);
    final entries = totals.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Where it went',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),

            // Segmented bar — proportional colored segments
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: entries.asMap().entries.map((e) {
                  final pct = total > 0
                      ? e.value.value / total
                      : 0.0;
                  return Expanded(
                    flex: (pct * 1000).round(),
                    child: Container(
                      height: 10,
                      color: AppColors.categories[
                          e.key % AppColors.categories.length],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Legend rows
            ...entries.asMap().entries.map((e) {
              final color = AppColors.categories[
                  e.key % AppColors.categories.length];
              final pct = total > 0
                  ? (e.value.value / total * 100)
                  : 0.0;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text(e.value.key,
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(
                      '₹${NumberFormat('#,##,###').format(e.value.value)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _TrendCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final maxY = data.fold<double>(0, (m, r) {
      final s = (r['spent'] as num?)?.toDouble() ?? 0;
      final i = (r['income'] as num?)?.toDouble() ?? 0;
      return [m, s, i].reduce((a, b) => a > b ? a : b);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('6-Month Trend',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Spacer(),
                _Dot(color: AppColors.income, label: 'Income'),
                SizedBox(width: 12),
                _Dot(color: AppColors.expense, label: 'Spent'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: BarChart(BarChartData(
                maxY: maxY * 1.2,
                barGroups: data.asMap().entries.map((e) {
                  final inc =
                      (e.value['income'] as num?)?.toDouble() ??
                          0;
                  final sp =
                      (e.value['spent'] as num?)?.toDouble() ?? 0;
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                        toY: inc,
                        color: AppColors.income,
                        width: 7,
                        borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(
                        toY: sp,
                        color: AppColors.expense,
                        width: 7,
                        borderRadius: BorderRadius.circular(4)),
                  ]);
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) {
                          return const Text('');
                        }
                        final m = (data[i]['month'] as String?) ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            m.length >= 7 ? m.substring(5) : m,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  const _EmptyState({required this.onImport});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('👋',
                style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Welcome to Artha',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Import your UPI SMS to get started.\nYour data stays on this phone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.sms_outlined, size: 18),
              label: const Text('Import from SMS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}