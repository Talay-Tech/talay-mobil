import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/rss_item_model.dart';
import '../../services/rss_service.dart';
import '../../talay_theme.dart';

/// Screen showing RSS news and announcements
class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  @override
  Widget build(BuildContext context) {
    final rssItemsAsync = ref.watch(rssItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Haberler & Duyurular',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: TalayTheme.primaryCyan,
        backgroundColor: TalayTheme.background,
        onRefresh: () async {
          ref.invalidate(rssItemsProvider);
        },
        child: rssItemsAsync.when(
          data: (items) => _buildNewsList(context, items),
          loading: () => const Center(
            child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: TalayTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Haberler yüklenirken hata oluştu',
                  style: TextStyle(color: TalayTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(rssItemsProvider),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList(BuildContext context, List<RssItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: TalayTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz haber yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: TalayTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'RSS kaynakları yönetici tarafından eklenebilir',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _NewsCard(item: item);
      },
    );
  }
}

/// Card widget for a single news item
class _NewsCard extends StatelessWidget {
  final RssItemModel item;

  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: TalayTheme.glassDecoration(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLink(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image if available
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Source and date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.sourceName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TalayTheme.secondaryPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.sourceName!,
                          style: TextStyle(
                            color: TalayTheme.secondaryPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (item.pubDate != null)
                      Text(
                        item.formattedDate,
                        style: TextStyle(
                          color: TalayTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Description
                if (item.cleanDescription.isNotEmpty)
                  Text(
                    item.cleanDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TalayTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Read more
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Devamını Oku',
                      style: TextStyle(
                        color: TalayTheme.primaryCyan,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: TalayTheme.primaryCyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context) async {
    if (item.link.isEmpty) return;

    final uri = Uri.tryParse(item.link);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link açılamadı: $e'),
            backgroundColor: TalayTheme.error,
          ),
        );
      }
    }
  }
}
