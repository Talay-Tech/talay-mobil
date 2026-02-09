import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction_model.dart';

class WalletManagementScreen extends ConsumerStatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  ConsumerState<WalletManagementScreen> createState() =>
      _WalletManagementScreenState();
}

class _WalletManagementScreenState
    extends ConsumerState<WalletManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final summary = ref.watch(walletSummaryProvider);

    return Scaffold(
      backgroundColor: TalayTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TalayTheme.textPrimary),
          onPressed: () => context.go('/profile'),
        ),
        title: Text(
          'Kasa Yönetimi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: TalayTheme.success,
        child: const Icon(Icons.add, color: TalayTheme.background),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            GlassCard(
              showGlow: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('Bakiye'),
                      summary.when(
                        data: (data) => Text(
                          '₺${data['balance']?.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: TalayTheme.primaryCyan,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const Text('...'),
                        error: (_, __) => const Text('₺0'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add Income / Expense Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showAddTransactionDialog(context, isIncome: true),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Gelir Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TalayTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showAddTransactionDialog(context, isIncome: false),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Gider Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TalayTheme.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Tüm İşlemler', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            transactions.when(
              data: (list) {
                if (list.isEmpty) {
                  return GlassCard(
                    child: Center(
                      child: Text(
                        'Henüz işlem yok',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }
                return Column(
                  children: list.map((t) {
                    return Dismissible(
                      key: Key(t.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await _showDeleteConfirmDialog(context, t);
                      },
                      onDismissed: (direction) async {
                        await _deleteTransaction(t.id);
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: TalayTheme.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: TalayTheme.error),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                t.isIncome
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: t.isIncome
                                    ? TalayTheme.success
                                    : TalayTheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.description),
                                    if (t.categoryName != null)
                                      Text(
                                        t.categoryName!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${t.isIncome ? '+' : '-'}₺${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: t.isIncome
                                      ? TalayTheme.success
                                      : TalayTheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: TalayTheme.error,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final confirmed =
                                      await _showDeleteConfirmDialog(
                                        context,
                                        t,
                                      );
                                  if (confirmed == true) {
                                    await _deleteTransaction(t.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('İşlemler yüklenemedi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTransactionDialog(
    BuildContext context, {
    bool isIncome = true,
  }) async {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TalayTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isIncome ? 'Gelir Ekle' : 'Gider Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Miktar (₺)',
                prefixText: '₺',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null &&
                  amount > 0 &&
                  descController.text.isNotEmpty) {
                final currentUser = ref.read(currentUserProvider).valueOrNull;
                if (currentUser != null) {
                  final service = ref.read(walletServiceProvider);
                  await service.addTransaction(
                    amount: amount,
                    type: isIncome
                        ? TransactionType.income
                        : TransactionType.expense,
                    description: descController.text,
                    createdBy: currentUser.id,
                  );
                  ref.invalidate(transactionsProvider);
                  ref.invalidate(walletSummaryProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? TalayTheme.success : TalayTheme.error,
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final service = ref.read(walletServiceProvider);
    await service.deleteTransaction(transactionId);
    ref.invalidate(transactionsProvider);
    ref.invalidate(walletSummaryProvider);
  }

  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    TransactionModel transaction,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TalayTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('İşlemi Sil'),
        content: Text(
          '${transaction.description} işlemini silmek istediğinize emin misiniz?\n\nMiktar: ${transaction.isIncome ? '+' : '-'}₺${transaction.amount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: TalayTheme.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
