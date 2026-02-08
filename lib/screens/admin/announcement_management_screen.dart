import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';

class AnnouncementManagementScreen extends ConsumerStatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  ConsumerState<AnnouncementManagementScreen> createState() =>
      _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState
    extends ConsumerState<AnnouncementManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final announcements = ref.watch(announcementsProvider);

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
          'Duyuru Yönetimi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAnnouncementDialog(context),
        backgroundColor: TalayTheme.warning,
        child: const Icon(Icons.add, color: TalayTheme.background),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: announcements.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.campaign,
                        color: TalayTheme.textSecondary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz duyuru yok',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddAnnouncementDialog(context),
                        child: const Text('Duyuru Ekle'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final announcement = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                              announcement.type,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(announcement.type),
                            color: _getTypeColor(announcement.type),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                announcement.content,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
          ),
          error: (_, __) => const Center(child: Text('Duyurular yüklenemedi')),
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'warning':
        return TalayTheme.warning;
      case 'success':
        return TalayTheme.success;
      case 'error':
        return TalayTheme.error;
      default:
        return TalayTheme.primaryCyan;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Future<void> _showAddAnnouncementDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'info';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: TalayTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Yeni Duyuru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'İçerik'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  dropdownColor: TalayTheme.background,
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('Bilgi')),
                    DropdownMenuItem(value: 'warning', child: Text('Uyarı')),
                    DropdownMenuItem(value: 'success', child: Text('Başarı')),
                    DropdownMenuItem(value: 'error', child: Text('Hata')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value ?? 'info');
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
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  final currentUser = ref.read(currentUserProvider).valueOrNull;
                  if (currentUser != null) {
                    final service = ref.read(announcementServiceProvider);
                    await service.createAnnouncement(
                      title: titleController.text,
                      content: contentController.text,
                      type: selectedType,
                      createdBy: currentUser.id,
                    );
                    ref.invalidate(announcementsProvider);
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
}
