import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Announcement model
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? type; // info, warning, success
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.type,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AnnouncementService {
  final SupabaseClient _client;

  AnnouncementService(this._client);

  /// Get active announcements
  Future<List<AnnouncementModel>> getAnnouncements() async {
    final response = await _client
        .from('announcements')
        .select()
        .order('created_at', ascending: false)
        .limit(5);

    return (response as List)
        .map((json) => AnnouncementModel.fromJson(json))
        .toList();
  }

  /// Create announcement (admin only)
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String content,
    String? type,
    required String createdBy,
  }) async {
    final response = await _client
        .from('announcements')
        .insert({
          'title': title,
          'content': content,
          'type': type ?? 'info',
          'created_by': createdBy,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return AnnouncementModel.fromJson(response);
  }
}

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AnnouncementService(client);
});

/// Provider for announcements
final announcementsProvider = FutureProvider<List<AnnouncementModel>>((
  ref,
) async {
  final service = ref.watch(announcementServiceProvider);
  return service.getAnnouncements();
});
