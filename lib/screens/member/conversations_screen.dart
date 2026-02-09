import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/messaging_service.dart';
import '../../talay_theme.dart';

/// Screen showing list of user's conversations
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mesajlar',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: conversationsAsync.when(
        data: (conversations) =>
            _buildConversationsList(context, conversations, currentUser),
        loading: () => const Center(
          child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Mesajlar yüklenirken hata oluştu',
            style: TextStyle(color: TalayTheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversationDialog(context),
        backgroundColor: TalayTheme.primaryCyan,
        child: const Icon(Icons.add, color: TalayTheme.background),
      ),
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    List<ConversationModel> conversations,
    UserModel? currentUser,
  ) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: TalayTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz mesajınız yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: TalayTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir sohbet başlatmak için + butonuna tıklayın',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationCard(
          conversation: conversation,
          currentUserId: currentUser?.id ?? '',
          onTap: () => context.push('/chat/${conversation.id}'),
        );
      },
    );
  }

  Future<void> _showNewConversationDialog(BuildContext context) async {
    final users = await ref.read(allUsersProvider.future);
    final currentUser = ref.read(currentUserProvider).valueOrNull;

    // Filter out current user
    final otherUsers = users.where((u) => u.id != currentUser?.id).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: TalayTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni Sohbet Başlat',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (otherUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Sohbet başlatılacak kullanıcı bulunamadı',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: otherUsers.length,
                  itemBuilder: (context, index) {
                    final user = otherUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: TalayTheme.secondaryPurple,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(color: TalayTheme.textPrimary),
                      ),
                      subtitle: Text(
                        user.email,
                        style: const TextStyle(color: TalayTheme.textSecondary),
                      ),
                      onTap: () => _startConversation(context, user.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startConversation(BuildContext context, String userId) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      final service = ref.read(messagingServiceProvider);
      final conversationId = await service.getOrCreateConversation(userId);

      if (mounted) {
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sohbet başlatılamadı: $e'),
            backgroundColor: TalayTheme.error,
          ),
        );
      }
    }
  }
}

/// Card widget for a single conversation
class _ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserName = conversation.otherUserName ?? 'Kullanıcı';
    final lastMessage = conversation.lastMessage ?? 'Henüz mesaj yok';
    final timeAgo = _formatTimeAgo(conversation.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: TalayTheme.glassDecoration(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: TalayTheme.secondaryPurple,
                  backgroundImage: conversation.otherUserAvatarUrl != null
                      ? NetworkImage(conversation.otherUserAvatarUrl!)
                      : null,
                  child: conversation.otherUserAvatarUrl == null
                      ? Text(
                          otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            otherUserName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            timeAgo,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: TalayTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TalayTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: TalayTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}dk';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}sa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
