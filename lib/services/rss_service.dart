import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webfeed_plus/webfeed_plus.dart';

import '../models/rss_source_model.dart';
import '../models/rss_item_model.dart';

/// Service for RSS feed operations
class RssService {
  final SupabaseClient _client;

  RssService(this._client);

  /// Get all active RSS sources
  Future<List<RssSourceModel>> getSources() async {
    final response = await _client
        .from('rss_sources')
        .select()
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((json) => RssSourceModel.fromJson(json))
        .toList();
  }

  /// Get all RSS sources (for admin)
  Future<List<RssSourceModel>> getAllSources() async {
    final response = await _client
        .from('rss_sources')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => RssSourceModel.fromJson(json))
        .toList();
  }

  /// Add new RSS source (admin only)
  Future<RssSourceModel> addSource({
    required String name,
    required String url,
    String category = 'genel',
  }) async {
    final response = await _client
        .from('rss_sources')
        .insert({
          'name': name,
          'url': url,
          'category': category,
          'is_active': true,
        })
        .select()
        .single();

    return RssSourceModel.fromJson(response);
  }

  /// Delete RSS source (admin only)
  Future<void> deleteSource(String sourceId) async {
    await _client.from('rss_sources').delete().eq('id', sourceId);
  }

  /// Toggle source active status (admin only)
  Future<void> toggleSourceActive(String sourceId, bool isActive) async {
    await _client
        .from('rss_sources')
        .update({'is_active': isActive})
        .eq('id', sourceId);
  }

  /// Fetch and parse RSS feed from URL
  Future<List<RssItemModel>> fetchFeed(RssSourceModel source) async {
    try {
      final response = await http.get(Uri.parse(source.url));
      if (response.statusCode != 200) {
        return [];
      }

      final items = <RssItemModel>[];

      // Try parsing as RSS first, then Atom
      try {
        final rssFeed = RssFeed.parse(response.body);
        for (final item in rssFeed.items ?? []) {
          items.add(
            RssItemModel(
              sourceId: source.id,
              title: item.title ?? 'Başlıksız',
              description: item.description,
              link: item.link ?? '',
              imageUrl:
                  item.enclosure?.url ??
                  _extractImageFromContent(item.content?.value),
              pubDate: item.pubDate,
              guid: item.guid ?? item.link,
              sourceName: source.name,
            ),
          );
        }
      } catch (_) {
        // Try Atom format
        try {
          final atomFeed = AtomFeed.parse(response.body);
          for (final entry in atomFeed.items ?? []) {
            items.add(
              RssItemModel(
                sourceId: source.id,
                title: entry.title ?? 'Başlıksız',
                description: entry.summary ?? entry.content,
                link: entry.links?.firstOrNull?.href ?? '',
                pubDate: entry.updated,
                guid: entry.id,
                sourceName: source.name,
              ),
            );
          }
        } catch (_) {
          // Could not parse feed
          return [];
        }
      }

      return items;
    } catch (e) {
      return [];
    }
  }

  /// Fetch all feeds from all active sources
  Future<List<RssItemModel>> fetchAllFeeds() async {
    final sources = await getSources();
    final allItems = <RssItemModel>[];

    for (final source in sources) {
      final items = await fetchFeed(source);
      allItems.addAll(items);
    }

    // Sort by publish date (newest first)
    allItems.sort((a, b) {
      if (a.pubDate == null && b.pubDate == null) return 0;
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allItems;
  }

  /// Extract image URL from HTML content
  String? _extractImageFromContent(String? content) {
    if (content == null) return null;
    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = imgRegex.firstMatch(content);
    return match?.group(1);
  }
}

/// Provider for RssService
final rssServiceProvider = Provider<RssService>((ref) {
  return RssService(Supabase.instance.client);
});

/// Future provider for all RSS items
final rssItemsProvider = FutureProvider<List<RssItemModel>>((ref) async {
  final service = ref.watch(rssServiceProvider);
  return service.fetchAllFeeds();
});

/// Future provider for RSS sources (admin)
final rssSourcesProvider = FutureProvider<List<RssSourceModel>>((ref) async {
  final service = ref.watch(rssServiceProvider);
  return service.getAllSources();
});
