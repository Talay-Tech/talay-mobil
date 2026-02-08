import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Service for messaging operations
class MessagingService {
  final SupabaseClient _client;

  MessagingService(this._client);

  /// Get current user's ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Get all conversations for the current user
  Future<List<ConversationModel>> getConversations() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('conversations')
        .select('''
          *,
          user_1:profiles!conversations_user_1_id_fkey(id, name, avatar_url),
          user_2:profiles!conversations_user_2_id_fkey(id, name, avatar_url)
        ''')
        .or('user_1_id.eq.$userId,user_2_id.eq.$userId')
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => ConversationModel.fromJson(json, currentUserId: userId))
        .toList();
  }

  /// Get or create a conversation with another user
  Future<String> getOrCreateConversation(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // First check if conversation exists
    final existing = await _client
        .from('conversations')
        .select('id')
        .or(
          'and(user_1_id.eq.$userId,user_2_id.eq.$otherUserId),and(user_1_id.eq.$otherUserId,user_2_id.eq.$userId)',
        )
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create new conversation
    final response = await _client
        .from('conversations')
        .insert({'user_1_id': userId, 'user_2_id': otherUserId})
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select('''
          *,
          sender:profiles!messages_sender_id_fkey(name)
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => MessageModel.fromJson(json))
        .toList();
  }

  /// Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'message': message,
        })
        .select()
        .single();

    return MessageModel.fromJson(response);
  }

  /// Stream of conversations for current user (with user details)
  Stream<List<ConversationModel>> conversationsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .asyncMap((data) async {
          // Filter conversations for current user
          final filtered = data
              .where(
                (json) =>
                    json['user_1_id'] == userId || json['user_2_id'] == userId,
              )
              .toList();

          if (filtered.isEmpty) return <ConversationModel>[];

          // Fetch with user details
          final ids = filtered.map((c) => c['id'] as String).toList();
          final enriched = await _client
              .from('conversations')
              .select('''
                *,
                user_1:profiles!conversations_user_1_id_fkey(id, name, avatar_url),
                user_2:profiles!conversations_user_2_id_fkey(id, name, avatar_url)
              ''')
              .inFilter('id', ids)
              .order('updated_at', ascending: false);

          return (enriched as List)
              .map(
                (json) =>
                    ConversationModel.fromJson(json, currentUserId: userId),
              )
              .toList();
        });
  }

  /// Stream of messages for a conversation (with sender details)
  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          if (data.isEmpty) return <MessageModel>[];

          // Fetch with sender details
          final enriched = await _client
              .from('messages')
              .select('''
                *,
                sender:profiles!messages_sender_id_fkey(name)
              ''')
              .eq('conversation_id', conversationId)
              .order('created_at', ascending: true);

          return (enriched as List)
              .map((json) => MessageModel.fromJson(json))
              .toList();
        });
  }
}

/// Provider for MessagingService
final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(Supabase.instance.client);
});

/// Stream provider for user's conversations (real-time)
final conversationsStreamProvider = StreamProvider<List<ConversationModel>>((
  ref,
) {
  final service = ref.watch(messagingServiceProvider);
  return service.conversationsStream();
});

/// Stream provider for messages in a specific conversation
final messagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
      final service = ref.watch(messagingServiceProvider);
      return service.messagesStream(conversationId);
    });
