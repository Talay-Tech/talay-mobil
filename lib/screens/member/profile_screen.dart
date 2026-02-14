import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/role_badge.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _showChangeNameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildDialog(
        title: 'Kullanıcı Adı Değiştir',
        icon: Icons.person_outline,
        child: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: TalayTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Yeni kullanıcı adı',
            prefixIcon: Icon(Icons.person, color: TalayTheme.primaryCyan),
          ),
        ),
        onConfirm: () => Navigator.pop(context, controller.text.trim()),
      ),
    );

    if (result != null && result.isNotEmpty && result != currentName) {
      await _performUpdate(
        () => ref.read(authServiceProvider).updateName(result),
        'Kullanıcı adı güncellendi',
      );
    }
  }

  Future<void> _showChangeEmailDialog(String currentEmail) async {
    final controller = TextEditingController(text: currentEmail);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildDialog(
        title: 'E-posta Değiştir',
        icon: Icons.email_outlined,
        child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: TalayTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Yeni e-posta adresi',
            prefixIcon: Icon(Icons.email, color: TalayTheme.primaryCyan),
          ),
        ),
        onConfirm: () => Navigator.pop(context, controller.text.trim()),
      ),
    );

    if (result != null && result.isNotEmpty && result != currentEmail) {
      await _performUpdate(
        () => ref.read(authServiceProvider).updateEmail(result),
        'Doğrulama e-postası gönderildi. Lütfen yeni e-postanızı kontrol edin.',
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _buildDialog(
        title: 'Şifre Değiştir',
        icon: Icons.lock_outline,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassController,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: TalayTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Yeni şifre',
                prefixIcon: Icon(Icons.lock, color: TalayTheme.primaryCyan),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              style: const TextStyle(color: TalayTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Yeni şifre (tekrar)',
                prefixIcon: Icon(
                  Icons.lock_reset,
                  color: TalayTheme.primaryCyan,
                ),
              ),
            ),
          ],
        ),
        onConfirm: () {
          if (newPassController.text.length < 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır')),
            );
            return;
          }
          if (newPassController.text != confirmPassController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Şifreler eşleşmiyor')),
            );
            return;
          }
          Navigator.pop(context, newPassController.text);
        },
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _performUpdate(
        () => ref.read(authServiceProvider).updatePassword(result),
        'Şifre başarıyla güncellendi',
      );
    }
  }

  Future<void> _performUpdate(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isLoading = true);
    try {
      await action();
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: TalayTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: TalayTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDialog({
    required String title,
    required IconData icon,
    required Widget child,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          Icon(icon, color: TalayTheme.primaryCyan, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: TalayTheme.textPrimary, fontSize: 18),
          ),
        ],
      ),
      content: child,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'İptal',
            style: TextStyle(color: TalayTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: TalayTheme.primaryCyan,
            foregroundColor: TalayTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: TalayTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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
                                  color: TalayTheme.primaryCyan.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                u.name.isNotEmpty
                                    ? u.name[0].toUpperCase()
                                    : '?',
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

                  // Profile Settings
                  Text(
                    'Hesap Ayarları',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  user.when(
                    data: (u) {
                      if (u == null) return const SizedBox();
                      return Column(
                        children: [
                          _MenuItem(
                            icon: Icons.person_outline,
                            label: 'Kullanıcı Adı Değiştir',
                            subtitle: u.name,
                            color: TalayTheme.primaryCyan,
                            onTap: () => _showChangeNameDialog(u.name),
                          ),
                          _MenuItem(
                            icon: Icons.email_outlined,
                            label: 'E-posta Değiştir',
                            subtitle: u.email,
                            color: TalayTheme.secondaryPurple,
                            onTap: () => _showChangeEmailDialog(u.email),
                          ),
                          _MenuItem(
                            icon: Icons.lock_outline,
                            label: 'Şifre Değiştir',
                            subtitle: '••••••••',
                            color: TalayTheme.accentMagenta,
                            onTap: () => _showChangePasswordDialog(),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 24),

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

                  // Other Settings
                  Text(
                    'Ayarlar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Bildirimler',
                    color: TalayTheme.warning,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yakında...')),
                      );
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
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: TalayTheme.primaryCyan,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TalayTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: TalayTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
