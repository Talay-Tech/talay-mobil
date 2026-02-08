/// Model representing an RSS source
class RssSourceModel {
  final String id;
  final String name;
  final String url;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  const RssSourceModel({
    required this.id,
    required this.name,
    required this.url,
    this.category = 'genel',
    this.isActive = true,
    required this.createdAt,
  });

  factory RssSourceModel.fromJson(Map<String, dynamic> json) {
    return RssSourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      category: json['category'] as String? ?? 'genel',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// For inserting new source (without id)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'url': url,
      'category': category,
      'is_active': isActive,
    };
  }

  RssSourceModel copyWith({
    String? id,
    String? name,
    String? url,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RssSourceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
