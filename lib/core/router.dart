import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/member/dashboard_screen.dart';
import '../screens/member/tasks_screen.dart';
import '../screens/member/task_detail_screen.dart';
import '../screens/member/wallet_screen.dart';
import '../screens/member/profile_screen.dart';
import '../screens/admin/admin_panel_screen.dart';
import '../screens/admin/task_management_screen.dart';
import '../screens/admin/wallet_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/announcement_management_screen.dart';
import '../screens/member/conversations_screen.dart';
import '../screens/member/chat_screen.dart';
import '../screens/member/news_screen.dart';
import '../screens/admin/rss_management_screen.dart';
import '../screens/shell_screen.dart';
import '../services/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main App Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
            routes: [
              GoRoute(
                path: ':taskId',
                builder: (context, state) {
                  final taskId = state.pathParameters['taskId']!;
                  return TaskDetailScreen(taskId: taskId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Messaging Routes
          GoRoute(
            path: '/conversations',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/chat/:conversationId',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId']!;
              return ChatScreen(conversationId: conversationId);
            },
          ),

          // Admin Routes
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminPanelScreen(),
          ),
          GoRoute(
            path: '/admin/tasks',
            builder: (context, state) => const TaskManagementScreen(),
          ),
          GoRoute(
            path: '/admin/wallet',
            builder: (context, state) => const WalletManagementScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/announcements',
            builder: (context, state) => const AnnouncementManagementScreen(),
          ),
          GoRoute(
            path: '/admin/rss',
            builder: (context, state) => const RssManagementScreen(),
          ),

          // News Route
          GoRoute(
            path: '/news',
            builder: (context, state) => const NewsScreen(),
          ),
        ],
      ),
    ],
  );
});
