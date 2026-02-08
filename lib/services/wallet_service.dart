import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import 'auth_service.dart';

class WalletService {
  final SupabaseClient _client;

  WalletService(this._client);

  /// Get all transactions
  Future<List<TransactionModel>> getTransactions() async {
    final response = await _client
        .from('wallet_transactions')
        .select('*, wallet_categories(name)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  /// Get wallet balance
  Future<double> getBalance() async {
    final transactions = await getTransactions();
    double balance = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  /// Get total income
  Future<double> getTotalIncome() async {
    final transactions = await getTransactions();
    double total = 0;
    for (final t in transactions) {
      if (t.isIncome) total += t.amount;
    }
    return total;
  }

  /// Get total expense
  Future<double> getTotalExpense() async {
    final transactions = await getTransactions();
    double total = 0;
    for (final t in transactions) {
      if (t.isExpense) total += t.amount;
    }
    return total;
  }

  /// Add transaction (admin only)
  Future<TransactionModel> addTransaction({
    required double amount,
    required TransactionType type,
    String? categoryId,
    required String description,
    required String createdBy,
  }) async {
    final response = await _client
        .from('wallet_transactions')
        .insert({
          'amount': amount,
          'type': type == TransactionType.income ? 'income' : 'expense',
          'category': categoryId,
          'description': description,
          'created_by': createdBy,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('*, wallet_categories(name)')
        .single();

    return TransactionModel.fromJson(response);
  }

  /// Get all categories
  Future<List<WalletCategory>> getCategories() async {
    final response = await _client
        .from('wallet_categories')
        .select()
        .order('name');

    return (response as List)
        .map((json) => WalletCategory.fromJson(json))
        .toList();
  }

  /// Delete a transaction (admin only)
  Future<void> deleteTransaction(String transactionId) async {
    await _client.from('wallet_transactions').delete().eq('id', transactionId);
  }
}

final walletServiceProvider = Provider<WalletService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WalletService(client);
});

/// Provider for wallet balance
final walletBalanceProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getBalance();
});

/// Provider for all transactions
final transactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final service = ref.watch(walletServiceProvider);
  return service.getTransactions();
});

/// Provider for wallet categories
final walletCategoriesProvider = FutureProvider<List<WalletCategory>>((
  ref,
) async {
  final service = ref.watch(walletServiceProvider);
  return service.getCategories();
});

/// Provider for wallet summary
final walletSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(walletServiceProvider);
  final balance = await service.getBalance();
  final income = await service.getTotalIncome();
  final expense = await service.getTotalExpense();

  return {'balance': balance, 'income': income, 'expense': expense};
});
