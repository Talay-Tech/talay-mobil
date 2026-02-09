import 'package:flutter/material.dart';

import '../talay_theme.dart';
import '../models/user_model.dart';

/// Badge widget showing user role (Member/Admin)
class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool large;

  const RoleBadge({super.key, required this.role, this.large = false});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    final color = isAdmin ? TalayTheme.secondaryPurple : TalayTheme.primaryCyan;
    final label = isAdmin ? 'Yönetici' : 'Üye';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: color,
            size: large ? 18 : 14,
          ),
          SizedBox(width: large ? 8 : 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
