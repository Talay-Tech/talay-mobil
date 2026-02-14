import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../talay_theme.dart';
import '../services/auth_service.dart';

class BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = currentUser?.isAdmin ?? false;

    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Ana Sayfa', index: 0),
      _NavItem(icon: Icons.task_alt_rounded, label: 'Görevler', index: 1),
      _NavItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Kasa',
        index: 2,
      ),
      _NavItem(icon: Icons.article_rounded, label: 'Haberler', index: 3),
      _NavItem(icon: Icons.person_rounded, label: 'Profil', index: 4),
      // Admin tab - only visible for admins
      if (isAdmin)
        _NavItem(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Yönetim',
          index: 5,
          isAdmin: true,
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.map((item) {
                final isSelected = currentIndex == item.index;
                return _buildNavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  isAdminItem: item.isAdmin,
                  onTap: () => onTap(item.index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    bool isAdminItem = false,
    required VoidCallback onTap,
  }) {
    final activeColor = isAdminItem
        ? TalayTheme.secondaryPurple
        : TalayTheme.primaryCyan;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : TalayTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : TalayTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  final bool isAdmin;

  _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    this.isAdmin = false,
  });
}
