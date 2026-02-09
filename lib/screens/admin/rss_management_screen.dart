import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/rss_source_model.dart';
import '../../services/rss_service.dart';
import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';

/// Admin screen for managing RSS sources
class RssManagementScreen extends ConsumerStatefulWidget {
  const RssManagementScreen({super.key});

  @override
  ConsumerState<RssManagementScreen> createState() =>
      _RssManagementScreenState();
}

class _RssManagementScreenState extends ConsumerState<RssManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(rssSourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RSS Kaynakları',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: sourcesAsync.when(
        data: (sources) => _buildSourcesList(context, sources),
        loading: () => const Center(
          child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Kaynaklar yüklenirken hata oluştu',
            style: TextStyle(color: TalayTheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSourceDialog(context),
        backgroundColor: TalayTheme.primaryCyan,
        child: const Icon(Icons.add, color: TalayTheme.background),
      ),
    );
  }

  Widget _buildSourcesList(BuildContext context, List<RssSourceModel> sources) {
    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rss_feed,
              size: 64,
              color: TalayTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz RSS kaynağı yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: TalayTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ butonuna tıklayarak yeni kaynak ekleyin',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return _SourceCard(
          source: source,
          onToggle: () => _toggleSource(source),
          onDelete: () => _deleteSource(source),
        );
      },
    );
  }

  Future<void> _showAddSourceDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TalayTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Yeni RSS Kaynağı',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Kaynak Adı',
                hintText: 'örn: Resmi Duyurular',
              ),
              style: const TextStyle(color: TalayTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'RSS URL',
                hintText: 'https://example.com/rss.xml',
              ),
              style: const TextStyle(color: TalayTheme.textPrimary),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(color: TalayTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();

              if (name.isNotEmpty && url.isNotEmpty) {
                Navigator.pop(context);
                await _addSource(name, url);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSource(String name, String url) async {
    try {
      final service = ref.read(rssServiceProvider);
      await service.addSource(name: name, url: url);
      ref.invalidate(rssSourcesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name kaynağı eklendi'),
            backgroundColor: TalayTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaynak eklenemedi: $e'),
            backgroundColor: TalayTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleSource(RssSourceModel source) async {
    try {
      final service = ref.read(rssServiceProvider);
      await service.toggleSourceActive(source.id, !source.isActive);
      ref.invalidate(rssSourcesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: $e'),
            backgroundColor: TalayTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSource(RssSourceModel source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TalayTheme.background,
        title: const Text('Kaynağı Sil'),
        content: Text(
          '${source.name} kaynağını silmek istediğinize emin misiniz?',
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

    if (confirmed == true) {
      try {
        final service = ref.read(rssServiceProvider);
        await service.deleteSource(source.id);
        ref.invalidate(rssSourcesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${source.name} silindi'),
              backgroundColor: TalayTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme başarısız: $e'),
              backgroundColor: TalayTheme.error,
            ),
          );
        }
      }
    }
  }
}

/// Card widget for RSS source
class _SourceCard extends StatelessWidget {
  final RssSourceModel source;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SourceCard({
    required this.source,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: source.isActive
                    ? TalayTheme.success
                    : TalayTheme.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Source info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source.url,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TalayTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Actions
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                source.isActive ? Icons.pause_circle : Icons.play_circle,
                color: source.isActive
                    ? TalayTheme.warning
                    : TalayTheme.success,
              ),
              tooltip: source.isActive ? 'Duraklat' : 'Aktifleştir',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: TalayTheme.error),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }
}
