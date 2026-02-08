import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/auth_service.dart';

/// Web Admin Panel - Main Dashboard
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: TalayTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TalayTheme.primaryCyan, TalayTheme.secondaryPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Talay Admin Panel',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          user.when(
            data: (u) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    u?.name ?? '',
                    style: const TextStyle(color: TalayTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: TalayTheme.secondaryPurple,
                    child: Text(
                      u?.name.isNotEmpty == true
                          ? u!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: isWide ? _buildWideLayout(context) : _buildNarrowLayout(context),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        SizedBox(width: 280, child: _buildMenuList(context)),
        const SizedBox(width: 24),
        // Main Content
        Expanded(child: _buildQuickStats(context)),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(context),
          const SizedBox(height: 24),
          _buildMenuList(context),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yönetim Menüsü', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _AdminMenuItem(
          icon: Icons.people,
          title: 'Kullanıcı Yönetimi',
          subtitle: 'Kullanıcı ekle, sil, rol ata',
          color: TalayTheme.secondaryPurple,
          onTap: () => context.go('/admin/users'),
        ),
        _AdminMenuItem(
          icon: Icons.task_alt,
          title: 'Görev Yönetimi',
          subtitle: 'Görev oluştur ve ata',
          color: TalayTheme.primaryCyan,
          onTap: () => context.go('/admin/tasks'),
        ),
        _AdminMenuItem(
          icon: Icons.account_balance_wallet,
          title: 'Kasa Yönetimi',
          subtitle: 'Gelir/gider işlemleri',
          color: TalayTheme.success,
          onTap: () => context.go('/admin/wallet'),
        ),
        _AdminMenuItem(
          icon: Icons.campaign,
          title: 'Duyuru Yönetimi',
          subtitle: 'Ana sayfa içerikleri',
          color: TalayTheme.warning,
          onTap: () => context.go('/admin/announcements'),
        ),
        _AdminMenuItem(
          icon: Icons.rss_feed,
          title: 'RSS Kaynakları',
          subtitle: 'Haber akışı yönetimi',
          color: TalayTheme.accentMagenta,
          onTap: () => context.go('/admin/rss'),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genel Bakış', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              icon: Icons.people,
              title: 'Kullanıcılar',
              value: '-',
              color: TalayTheme.secondaryPurple,
            ),
            _StatCard(
              icon: Icons.task_alt,
              title: 'Aktif Görevler',
              value: '-',
              color: TalayTheme.primaryCyan,
            ),
            _StatCard(
              icon: Icons.account_balance_wallet,
              title: 'Kasa Bakiyesi',
              value: '₺-',
              color: TalayTheme.success,
            ),
            _StatCard(
              icon: Icons.campaign,
              title: 'Duyurular',
              value: '-',
              color: TalayTheme.warning,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: color),
            ),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
