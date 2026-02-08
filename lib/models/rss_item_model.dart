/// Model representing an RSS feed item
class RssItemModel {
  final String? id;
  final String? sourceId;
  final String title;
  final String? description;
  final String link;
  final String? imageUrl;
  final DateTime? pubDate;
  final String? guid;
  final String? sourceName;

  const RssItemModel({
    this.id,
    this.sourceId,
    required this.title,
    this.description,
    required this.link,
    this.imageUrl,
    this.pubDate,
    this.guid,
    this.sourceName,
  });

  factory RssItemModel.fromJson(Map<String, dynamic> json) {
    String? sourceName;
    if (json['rss_sources'] != null) {
      sourceName = json['rss_sources']['name'] as String?;
    }

    return RssItemModel(
      id: json['id'] as String?,
      sourceId: json['source_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      link: json['link'] as String,
      imageUrl: json['image_url'] as String?,
      pubDate: json['pub_date'] != null
          ? DateTime.parse(json['pub_date'] as String)
          : null,
      guid: json['guid'] as String?,
      sourceName: sourceName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_id': sourceId,
      'title': title,
      'description': description,
      'link': link,
      'image_url': imageUrl,
      'pub_date': pubDate?.toIso8601String(),
      'guid': guid,
    };
  }

  /// Format publish date for display
  String get formattedDate {
    if (pubDate == null) return '';
    final now = DateTime.now();
    final diff = now.difference(pubDate!);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${pubDate!.day}/${pubDate!.month}/${pubDate!.year}';
    }
  }

  /// Clean description from HTML tags
  String get cleanDescription {
    if (description == null) return '';
    // Remove HTML tags
    return description!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
