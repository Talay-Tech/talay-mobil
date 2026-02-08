import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';
import '../models/transaction_model.dart';
import '../services/announcement_service.dart';

/// Real-time providers for live data updates

// ============ TASKS REAL-TIME ============

/// Stream provider for user's tasks (real-time)
final userTasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  return client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('assigned_to', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => TaskModel.fromJson(json)).toList());
});

/// Stream provider for all tasks (admin, real-time)
final allTasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final client = Supabase.instance.client;

  return client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => TaskModel.fromJson(json)).toList());
});

// ============ WALLET REAL-TIME ============

/// Stream provider for transactions (real-time)
final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  final client = Supabase.instance.client;

  return client
      .from('wallet_transactions')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map(
        (data) => data.map((json) => TransactionModel.fromJson(json)).toList(),
      );
});

/// Derived provider for wallet balance (real-time)
final walletBalanceStreamProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  double balance = 0;
  for (final t in transactions) {
    if (t.isIncome) {
      balance += t.amount;
    } else {
      balance -= t.amount;
    }
  }
  return balance;
});

// ============ ANNOUNCEMENTS REAL-TIME ============

/// Stream provider for announcements (real-time)
final announcementsStreamProvider = StreamProvider<List<AnnouncementModel>>((
  ref,
) {
  final client = Supabase.instance.client;

  return client
      .from('announcements')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(10)
      .map(
        (data) => data.map((json) => AnnouncementModel.fromJson(json)).toList(),
      );
});

// ============ USERS REAL-TIME (Admin) ============

/// Stream provider for all users (admin, real-time)
final allUsersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final client = Supabase.instance.client;

  return client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);
});
