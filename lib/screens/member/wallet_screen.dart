import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(walletSummaryProvider);
    final transactions = ref.watch(transactionsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: TalayTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Takım Kasası',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // Balance Card
              GlassCard(
                showGlow: true,
                child: Column(
                  children: [
                    Text(
                      'Toplam Bakiye',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    summary.when(
                      data: (data) => Text(
                        '₺${data['balance']?.toStringAsFixed(2) ?? '0.00'}',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: TalayTheme.primaryCyan,
                              fontSize: 36,
                            ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('₺0.00'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Income / Expense Row
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: TalayTheme.success,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Gelir',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          summary.when(
                            data: (data) => Text(
                              '₺${data['income']?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                color: TalayTheme.success,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const Text('...'),
                            error: (_, __) => const Text('₺0.00'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: TalayTheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Gider',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          summary.when(
                            data: (data) => Text(
                              '₺${data['expense']?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                color: TalayTheme.error,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const Text('...'),
                            error: (_, __) => const Text('₺0.00'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chart
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gelir / Gider Dağılımı',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: summary.when(
                        data: (data) {
                          final income = data['income'] ?? 0;
                          final expense = data['expense'] ?? 0;
                          if (income == 0 && expense == 0) {
                            return Center(
                              child: Text(
                                'Henüz işlem yok',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }
                          return PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: income,
                                  color: TalayTheme.success,
                                  title: 'Gelir',
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: expense,
                                  color: TalayTheme.error,
                                  title: 'Gider',
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) =>
                            const Center(child: Text('Grafik yüklenemedi')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transactions List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son İşlemler',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
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
                    children: list.take(10).map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      (t.isIncome
                                              ? TalayTheme.success
                                              : TalayTheme.error)
                                          .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  t.isIncome
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: t.isIncome
                                      ? TalayTheme.success
                                      : TalayTheme.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.description,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
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
                            ],
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
      ),
    );
  }
}
