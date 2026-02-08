import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/role_badge.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client.from('profiles').select().order('created_at');
  return (response as List).map((json) => UserModel.fromJson(json)).toList();
});

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);

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
          'Kullanıcı Yönetimi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: users.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'Kullanıcı bulunamadı',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final user = list[index];
                return _UserCard(
                  user: user,
                  onRoleChanged: () => ref.invalidate(allUsersProvider),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
          ),
          error: (_, __) =>
              const Center(child: Text('Kullanıcılar yüklenemedi')),
        ),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onRoleChanged;

  const _UserCard({required this.user, required this.onRoleChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: user.isAdmin
                      ? [TalayTheme.secondaryPurple, TalayTheme.accentMagenta]
                      : [TalayTheme.primaryCyan, TalayTheme.secondaryPurple],
                ),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: TalayTheme.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuButton<UserRole>(
              icon: const Icon(
                Icons.more_vert,
                color: TalayTheme.textSecondary,
              ),
              color: TalayTheme.background,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: UserRole.member,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: user.isMember
                            ? TalayTheme.primaryCyan
                            : TalayTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Üye',
                        style: TextStyle(
                          color: user.isMember
                              ? TalayTheme.primaryCyan
                              : TalayTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: UserRole.admin,
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: user.isAdmin
                            ? TalayTheme.secondaryPurple
                            : TalayTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yönetici',
                        style: TextStyle(
                          color: user.isAdmin
                              ? TalayTheme.secondaryPurple
                              : TalayTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (newRole) async {
                if (newRole != user.role) {
                  final authService = ref.read(authServiceProvider);
                  await authService.updateUserRole(user.id, newRole);
                  onRoleChanged();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${user.name} rolü güncellendi'),
                        backgroundColor: TalayTheme.success,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
