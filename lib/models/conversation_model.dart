/// Model representing a conversation between two users
class ConversationModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime updatedAt;
  final DateTime createdAt;

  /// Other user's profile info (populated from join)
  final String? otherUserName;
  final String? otherUserAvatarUrl;

  const ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    required this.updatedAt,
    required this.createdAt,
    this.otherUserName,
    this.otherUserAvatarUrl,
  });

  /// Get the other user's ID based on current user
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    String? otherName;
    String? otherAvatar;

    // Extract other user info from joined data
    if (currentUserId != null) {
      final isUser1 = json['user_1_id'] == currentUserId;
      final otherUserKey = isUser1 ? 'user_2' : 'user_1';

      if (json[otherUserKey] != null) {
        otherName = json[otherUserKey]['name'] as String?;
        otherAvatar = json[otherUserKey]['avatar_url'] as String?;
      }
    }

    return ConversationModel(
      id: json['id'] as String,
      user1Id: json['user_1_id'] as String,
      user2Id: json['user_2_id'] as String,
      lastMessage: json['last_message'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      otherUserName: otherName,
      otherUserAvatarUrl: otherAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_1_id': user1Id,
      'user_2_id': user2Id,
      'last_message': lastMessage,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? lastMessage,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? otherUserName,
    String? otherUserAvatarUrl,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
    );
  }
}
