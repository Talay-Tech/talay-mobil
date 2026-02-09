import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../talay_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/countdown_widget.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/wallet_service.dart';
import '../../services/announcement_service.dart';

/// Location provider
final userLocationProvider = StreamProvider<Position?>((ref) {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    ),
  );
});

/// Bearing to workshop provider
final bearingToWorkshopProvider = Provider<double>((ref) {
  final location = ref.watch(userLocationProvider).valueOrNull;
  if (location == null) return 0;

  return Geolocator.bearingBetween(
    location.latitude,
    location.longitude,
    AppConstants.workshopLatitude,
    AppConstants.workshopLongitude,
  );
});

/// Distance to workshop provider
final distanceToWorkshopProvider = Provider<double>((ref) {
  final location = ref.watch(userLocationProvider).valueOrNull;
  if (location == null) return 0;

  return Geolocator.distanceBetween(
    location.latitude,
    location.longitude,
    AppConstants.workshopLatitude,
    AppConstants.workshopLongitude,
  );
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationPermissionGranted = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    setState(() {
      _locationPermissionGranted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final tasks = ref.watch(userTasksProvider);
    final walletSummary = ref.watch(walletSummaryProvider);
    final announcements = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: TalayTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, user),
              const SizedBox(height: 20),

              // Countdown Timer (en üstte)
              const CountdownWidget(),
              const SizedBox(height: 20),

              // Compass Direction Indicator
              _buildCompassCard(context),
              const SizedBox(height: 20),

              // Announcements
              _buildAnnouncementsSection(context, announcements),
              const SizedBox(height: 20),

              // Stats Row
              _buildStatsRow(context, tasks, walletSummary),
              const SizedBox(height: 20),

              // Admin Quick Actions (only for admins)
              _buildAdminQuickActions(context, user),

              // Recent Tasks
              _buildRecentTasks(context, tasks),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merhaba,', style: Theme.of(context).textTheme.bodyMedium),
            user.when(
              data: (u) => Text(
                u?.name ?? 'Kullanıcı',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const Text('...'),
              error: (_, __) => const Text('Hata'),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TalayTheme.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: TalayTheme.primaryCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildCompassCard(BuildContext context) {
    final bearing = ref.watch(bearingToWorkshopProvider);
    final distance = ref.watch(distanceToWorkshopProvider);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      showGlow: true,
      child: Column(
        children: [
          Text('Atölye Yönü', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            width: 150,
            child: _locationPermissionGranted
                ? _CompassWidget(targetBearing: bearing)
                : _buildLocationDisabled(),
          ),
          const SizedBox(height: 12),
          Text(
            AppConstants.workshopName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: TalayTheme.primaryCyan),
          ),
          if (_locationPermissionGranted && distance > 0) ...[
            const SizedBox(height: 4),
            Text(
              _formatDistance(distance),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: TalayTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationDisabled() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_off, color: TalayTheme.textSecondary, size: 48),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _checkLocationPermission,
          child: const Text('Konumu Etkinleştir'),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsSection(
    BuildContext context,
    AsyncValue<List<AnnouncementModel>> announcements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.campaign, color: TalayTheme.warning, size: 20),
            const SizedBox(width: 8),
            Text('Duyurular', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        announcements.when(
          data: (list) {
            if (list.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: TalayTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      'Henüz duyuru yok',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: list.take(3).map((announcement) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getAnnouncementColor(
                              announcement.type,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAnnouncementIcon(announcement.type),
                            color: _getAnnouncementColor(announcement.type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                announcement.content,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Duyurular yüklenemedi'),
        ),
      ],
    );
  }

  Color _getAnnouncementColor(String? type) {
    switch (type) {
      case 'warning':
        return TalayTheme.warning;
      case 'success':
        return TalayTheme.success;
      case 'error':
        return TalayTheme.error;
      default:
        return TalayTheme.primaryCyan;
    }
  }

  IconData _getAnnouncementIcon(String? type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Widget _buildStatsRow(
    BuildContext context,
    AsyncValue tasks,
    AsyncValue walletSummary,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt,
                          color: TalayTheme.primaryCyan,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Görevler',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    tasks.when(
                      data: (list) => Text(
                        '${list.length}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: TalayTheme.primaryCyan),
                      ),
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('0'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: TalayTheme.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kasa',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    walletSummary.when(
                      data: (summary) => Text(
                        '₺${summary['balance']?.toStringAsFixed(0) ?? 0}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: TalayTheme.success),
                      ),
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('₺0'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Messaging Card
        GestureDetector(
          onTap: () => context.go('/conversations'),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TalayTheme.accentMagenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: TalayTheme.accentMagenta,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesajlar',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ekip ile mesajlaşın',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TalayTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: TalayTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // News Card
        GestureDetector(
          onTap: () => context.go('/news'),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TalayTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: TalayTheme.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haberler & Duyurular',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Güncel haberleri takip edin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TalayTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: TalayTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTasks(BuildContext context, AsyncValue tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son Görevler', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        tasks.when(
          data: (list) {
            if (list.isEmpty) {
              return GlassCard(
                child: Center(
                  child: Text(
                    'Henüz görev yok',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return Column(
              children: list.take(3).map((task) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getStatusColor(task.status.name),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                task.statusLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: TalayTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Görevler yüklenemedi'),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'inProgress':
        return TalayTheme.warning;
      case 'done':
        return TalayTheme.success;
      default:
        return TalayTheme.textSecondary;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m uzaklıkta';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km uzaklıkta';
    }
  }

  Widget _buildAdminQuickActions(BuildContext context, AsyncValue user) {
    return user.when(
      data: (u) {
        if (u == null || !u.isAdmin) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: TalayTheme.secondaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hızlı İşlemler',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person_add,
                    label: 'Görev Ata',
                    color: TalayTheme.primaryCyan,
                    onTap: () => context.go('/admin/tasks'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle,
                    label: 'Kasa İşlemi',
                    color: TalayTheme.success,
                    onTap: () => context.go('/admin/wallet'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.campaign,
                    label: 'Duyuru',
                    color: TalayTheme.warning,
                    onTap: () => context.go('/admin/announcements'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.people,
                    label: 'Kullanıcılar',
                    color: TalayTheme.secondaryPurple,
                    onTap: () => context.go('/admin/users'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Compass widget that points to target bearing (static direction indicator)
class _CompassWidget extends StatefulWidget {
  final double targetBearing;

  const _CompassWidget({required this.targetBearing});

  @override
  State<_CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<_CompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousBearing = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.targetBearing,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_CompassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetBearing != widget.targetBearing) {
      _previousBearing = _animation.value;
      _animation =
          Tween<double>(
            begin: _previousBearing,
            end: widget.targetBearing,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final arrowDirection = _animation.value * math.pi / 180;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            CustomPaint(
              size: const Size(150, 150),
              painter: _CompassRingPainter(),
            ),
            // Arrow pointing to workshop
            Transform.rotate(
              angle: arrowDirection,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: TalayTheme.primaryCyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TalayTheme.primaryCyan.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  color: TalayTheme.primaryCyan,
                  size: 40,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Quick Action Button Widget for Admin
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: TalayTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    final ringPaint = Paint()
      ..color = TalayTheme.primaryCyan.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 5, ringPaint);

    // Direction markers
    final markerPaint = Paint()
      ..color = TalayTheme.textSecondary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * math.pi / 180;
      final x = center.dx + (radius - 15) * math.cos(angle);
      final y = center.dy + (radius - 15) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), i % 2 == 0 ? 4 : 2, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
