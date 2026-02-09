import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/role_badge.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: TalayTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Avatar
              user.when(
                data: (u) {
                  if (u == null) return const SizedBox();
                  return Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              TalayTheme.primaryCyan,
                              TalayTheme.secondaryPurple,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TalayTheme.primaryCyan.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: TalayTheme.background,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        u.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        u.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      RoleBadge(role: u.role, large: true),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Profil yüklenemedi'),
              ),
              const SizedBox(height: 32),

              // Admin Menu (only for admins)
              user.when(
                data: (u) {
                  if (u == null || !u.isAdmin) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yönetici Menüsü',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _MenuItem(
                        icon: Icons.admin_panel_settings,
                        label: 'Admin Panel',
                        color: TalayTheme.accentMagenta,
                        onTap: () => context.go('/admin'),
                      ),
                      _MenuItem(
                        icon: Icons.task_alt,
                        label: 'Görev Yönetimi',
                        color: TalayTheme.primaryCyan,
                        onTap: () => context.go('/admin/tasks'),
                      ),
                      _MenuItem(
                        icon: Icons.account_balance_wallet,
                        label: 'Kasa Yönetimi',
                        color: TalayTheme.success,
                        onTap: () => context.go('/admin/wallet'),
                      ),
                      _MenuItem(
                        icon: Icons.people,
                        label: 'Kullanıcı Yönetimi',
                        color: TalayTheme.secondaryPurple,
                        onTap: () => context.go('/admin/users'),
                      ),
                      _MenuItem(
                        icon: Icons.campaign,
                        label: 'Duyuru Yönetimi',
                        color: TalayTheme.warning,
                        onTap: () => context.go('/admin/announcements'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

              // Settings
              Text('Ayarlar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Bildirimler',
                color: TalayTheme.warning,
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Yakında...')));
                },
              ),
              _MenuItem(
                icon: Icons.info_outline,
                label: 'Hakkında',
                color: TalayTheme.textSecondary,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Talay',
                    applicationVersion: '1.0.0',
                    children: [const Text('Ekip Yönetimi Uygulaması')],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, color: TalayTheme.error),
                  label: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: TalayTheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TalayTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(Icons.chevron_right, color: TalayTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
