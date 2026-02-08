import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';
import 'auth_service.dart';

class TaskService {
  final SupabaseClient _client;

  TaskService(this._client);

  /// Get all tasks assigned to a user
  Future<List<TaskModel>> getTasksForUser(String userId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('assigned_to', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Get all tasks (admin)
  Future<List<TaskModel>> getAllTasks() async {
    final response = await _client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Get single task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('id', taskId)
        .single();

    return TaskModel.fromJson(response);
  }

  /// Create a new task (admin)
  Future<TaskModel> createTask({
    required String title,
    String? description,
    required String assignedTo,
    required String createdBy,
    DateTime? dueDate,
  }) async {
    final response = await _client
        .from('tasks')
        .insert({
          'title': title,
          'description': description,
          'status': 'todo',
          'assigned_to': assignedTo,
          'created_by': createdBy,
          'due_date': dueDate?.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  /// Update task status (member can update their own tasks)
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    String statusString;
    switch (status) {
      case TaskStatus.inProgress:
        statusString = 'in_progress';
        break;
      case TaskStatus.done:
        statusString = 'done';
        break;
      default:
        statusString = 'todo';
    }

    await _client
        .from('tasks')
        .update({'status': statusString})
        .eq('id', taskId);
  }

  /// Update task (admin)
  Future<void> updateTask(TaskModel task) async {
    await _client.from('tasks').update(task.toJson()).eq('id', task.id);
  }

  /// Delete task (admin)
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  /// Update task assignment (admin)
  Future<void> updateTaskAssignment(String taskId, String userId) async {
    await _client
        .from('tasks')
        .update({'assigned_to': userId})
        .eq('id', taskId);
  }
}

final taskServiceProvider = Provider<TaskService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TaskService(client);
});

/// Provider for current user's tasks
final userTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];

  final service = ref.watch(taskServiceProvider);
  return service.getTasksForUser(user.id);
});

/// Provider for all tasks (admin)
final allTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final service = ref.watch(taskServiceProvider);
  return service.getAllTasks();
});
