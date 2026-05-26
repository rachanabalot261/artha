import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/category_model.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends ConsumerState<TransactionsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(monthlyTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spends'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
        ),
      ),
      body: txAsync.when(
        data: (all) {
          // Filter by search query
          final list = all.where((t) {
            if (_q.isEmpty) return true;
            return t.merchant
                    .toLowerCase()
                    .contains(_q.toLowerCase()) ||
                t.category
                    .toLowerCase()
                    .contains(_q.toLowerCase());
          }).toList();

          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 56, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No transactions',
                      style:
                          TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: list.length,
            itemBuilder: (_, i) => _TxTile(
              tx: list[i],
              onDelete: () async {
                await DatabaseHelper.instance
                    .delete(list[i].id!);
                refreshAll(ref);
              },
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.purple)),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context),
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.add),
        label: const Text('Add',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // Bottom sheet for manual transaction entry
  void _addDialog(BuildContext context) {
    final mc = TextEditingController();
    final ac = TextEditingController();
    String type = 'debit';
    String cat = 'Other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: StatefulBuilder(
          builder: (_, ss) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Transaction',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: mc,
                decoration: const InputDecoration(
                    labelText: 'Merchant / Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ac,
                decoration:
                    const InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                          labelText: 'Type'),
                      items: ['debit', 'credit']
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          ss(() => type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: cat,
                      decoration: const InputDecoration(
                          labelText: 'Category'),
                      items: CategoryModel.defaults()
                          .map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name)))
                          .toList(),
                      onChanged: (v) =>
                          ss(() => cat = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amt =
                        double.tryParse(ac.text);
                    if (mc.text.isEmpty || amt == null) return;
                    await DatabaseHelper.instance.insert(
                      TransactionModel(
                        merchant: mc.text,
                        amount: amt,
                        category: cat,
                        type: type,
                        date: DateTime.now(),
                        source: 'manual',
                      ),
                    );
                    refreshAll(ref);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onDelete;
  const _TxTile(
      {required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDebit = tx.type == 'debit';

    return Dismissible(
      key: Key('${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.expense),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Delete?'),
          content: Text('Remove ${tx.merchant}?'),
          actions: [
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(
                        color: AppColors.expense))),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Category emoji icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isDebit
                        ? AppColors.expense
                        : AppColors.income)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  CategoryModel.iconFor(tx.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(tx.merchant,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.category} • ${DateFormat('d MMM').format(tx.date)}',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            // Amount — red for debit, green for credit
            Text(
              '${isDebit ? '−' : '+'}₹${NumberFormat('#,##,###').format(tx.amount)}',
              style: TextStyle(
                color: isDebit
                    ? AppColors.expense
                    : AppColors.income,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}