import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(TaskStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final service = ref.read(taskServiceProvider);
      await service.updateTaskStatus(widget.taskId, newStatus);
      ref.invalidate(userTasksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Görev durumu güncellendi'),
            backgroundColor: TalayTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Güncelleme başarısız'),
            backgroundColor: TalayTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksFuture = ref.watch(userTasksProvider);

    return Scaffold(
      backgroundColor: TalayTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TalayTheme.textPrimary),
          onPressed: () => context.go('/tasks'),
        ),
        title: Text(
          'Görev Detayı',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: tasksFuture.when(
        data: (tasks) {
          final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
          if (task == null) {
            return const Center(child: Text('Görev bulunamadı'));
          }
          return _buildContent(context, task);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
        ),
        error: (_, __) => const Center(child: Text('Hata oluştu')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TaskModel task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    _StatusBadge(status: task.status),
                  ],
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    task.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Task Info
          GlassCard(
            child: Column(
              children: [
                if (task.dueDate != null)
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Bitiş Tarihi',
                    value: _formatDate(task.dueDate!),
                  ),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Oluşturulma',
                  value: _formatDate(task.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status Update Buttons
          Text(
            'Durumu Güncelle',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          if (_isUpdating)
            const Center(
              child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: 'Yapılacak',
                    color: TalayTheme.textSecondary,
                    isSelected: task.status == TaskStatus.todo,
                    onTap: () => _updateStatus(TaskStatus.todo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusButton(
                    label: 'Devam Ediyor',
                    color: TalayTheme.warning,
                    isSelected: task.status == TaskStatus.inProgress,
                    onTap: () => _updateStatus(TaskStatus.inProgress),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusButton(
                    label: 'Tamamlandı',
                    color: TalayTheme.success,
                    isSelected: task.status == TaskStatus.done,
                    onTap: () => _updateStatus(TaskStatus.done),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case TaskStatus.inProgress:
        color = TalayTheme.warning;
        label = 'Devam Ediyor';
        break;
      case TaskStatus.done:
        color = TalayTheme.success;
        label = 'Tamamlandı';
        break;
      default:
        color = TalayTheme.textSecondary;
        label = 'Yapılacak';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: TalayTheme.primaryCyan, size: 20),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : TalayTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
