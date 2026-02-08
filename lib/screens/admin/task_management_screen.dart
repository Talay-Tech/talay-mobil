import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';

class TaskManagementScreen extends ConsumerStatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  ConsumerState<TaskManagementScreen> createState() =>
      _TaskManagementScreenState();
}

class _TaskManagementScreenState extends ConsumerState<TaskManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(allTasksProvider);
    final users = ref.watch(allUsersProvider);

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
          'Görev Yönetimi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, users.valueOrNull ?? []),
        backgroundColor: TalayTheme.primaryCyan,
        child: const Icon(Icons.add, color: TalayTheme.background),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: tasks.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task_alt,
                        color: TalayTheme.textSecondary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz görev yok',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddTaskDialog(
                          context,
                          users.valueOrNull ?? [],
                        ),
                        child: const Text('Görev Ekle'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final task = list[index];
                return _TaskAdminCard(
                  task: task,
                  users: users.valueOrNull ?? [],
                  onDelete: () => _deleteTask(task.id),
                  onAssign: (userId) => _assignTask(task.id, userId),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
          ),
          error: (_, __) => const Center(child: Text('Görevler yüklenemedi')),
        ),
      ),
    );
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    List<UserModel> users,
  ) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedUserId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: TalayTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Yeni Görev'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Görev Başlığı'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // User Selector Dropdown
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Atanacak Kişi',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: TalayTheme.surface,
                  items: users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: TalayTheme.secondaryPurple,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedUserId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && selectedUserId != null) {
                  final currentUser = ref.read(currentUserProvider).valueOrNull;
                  if (currentUser != null) {
                    final service = ref.read(taskServiceProvider);
                    await service.createTask(
                      title: titleController.text,
                      description: descController.text,
                      assignedTo: selectedUserId!,
                      createdBy: currentUser.id,
                    );
                    ref.invalidate(allTasksProvider);
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    final service = ref.read(taskServiceProvider);
    await service.deleteTask(taskId);
    ref.invalidate(allTasksProvider);
  }

  Future<void> _assignTask(String taskId, String userId) async {
    final service = ref.read(taskServiceProvider);
    await service.updateTaskAssignment(taskId, userId);
    ref.invalidate(allTasksProvider);
  }
}

class _TaskAdminCard extends StatelessWidget {
  final TaskModel task;
  final List<UserModel> users;
  final VoidCallback onDelete;
  final Function(String) onAssign;

  const _TaskAdminCard({
    required this.task,
    required this.users,
    required this.onDelete,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final assignedUser = users
        .where((u) => u.id == task.assignedTo)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (assignedUser != null) ...[
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: TalayTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              assignedUser.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: TalayTheme.textSecondary,
                  ),
                  color: TalayTheme.surface,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 20),
                          SizedBox(width: 8),
                          Text('Kişi Ata'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: TalayTheme.error),
                          SizedBox(width: 8),
                          Text(
                            'Sil',
                            style: TextStyle(color: TalayTheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(context);
                    } else if (value == 'assign') {
                      _showAssignDialog(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.orange;
      case TaskStatus.inProgress:
        return TalayTheme.primaryCyan;
      case TaskStatus.done:
        return TalayTheme.success;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TalayTheme.background,
        title: const Text('Görevi Sil'),
        content: const Text('Bu görevi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: TalayTheme.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TalayTheme.background,
        title: const Text('Kişi Ata'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isSelected = user.id == task.assignedTo;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? TalayTheme.primaryCyan
                      : TalayTheme.secondaryPurple,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: isSelected
                    ? const Icon(Icons.check, color: TalayTheme.success)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onAssign(user.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}
