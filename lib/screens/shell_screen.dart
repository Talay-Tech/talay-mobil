import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/update_dialog.dart';
import '../talay_theme.dart';
import '../services/update_service.dart';

/// Shell screen with bottom navigation
class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 0;
  bool _hasCheckedUpdate = false;

  final _routes = [
    '/dashboard',
    '/tasks',
    '/wallet',
    '/news',
    '/profile',
    '/admin',
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  void initState() {
    super.initState();
    // Güncelleme kontrolünü bir frame sonra yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;

    // Kullanıcı daha önce atladıysa kontrol etme
    final skipped = ref.read(skipUpdateProvider);
    if (skipped) {
      debugPrint('🔄 Update check skipped by user');
      return;
    }

    try {
      debugPrint('🔄 Checking for update...');
      final result = await ref.read(updateCheckResultProvider.future);
      debugPrint('🔄 Update status: ${result.status}');
      debugPrint('🔄 Has update: ${result.hasUpdate}');

      if (result.updateInfo != null) {
        debugPrint('🔄 Latest version: ${result.updateInfo!.latestVersion}');
        debugPrint('🔄 Download URL: ${result.updateInfo!.apkDownloadUrl}');
      }

      if (result.hasUpdate && result.updateInfo != null && mounted) {
        final packageInfo = await ref.read(packageInfoProvider.future);
        debugPrint('🔄 Current version: ${packageInfo.version}');
        debugPrint('🔄 Showing update dialog...');

        await UpdateDialog.show(
          context,
          updateInfo: result.updateInfo!,
          currentVersion: packageInfo.version,
          onSkip: () {
            // Kullanıcı "Sonra" dedi, bu oturum için atla
            ref.read(skipUpdateProvider.notifier).state = true;
          },
        );
      } else {
        debugPrint('🔄 No update needed or not mounted');
      }
    } catch (e) {
      // Güncelleme kontrolü başarısız - sessizce devam et
      debugPrint('❌ Update check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update current index based on location
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin'))
      _currentIndex = 5;
    else if (location.startsWith('/dashboard'))
      _currentIndex = 0;
    else if (location.startsWith('/tasks'))
      _currentIndex = 1;
    else if (location.startsWith('/wallet'))
      _currentIndex = 2;
    else if (location.startsWith('/news'))
      _currentIndex = 3;
    else if (location.startsWith('/profile'))
      _currentIndex = 4;

    return Scaffold(
      backgroundColor: TalayTheme.background,
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
