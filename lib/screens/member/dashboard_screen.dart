import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
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

/// Location provider - permissions are checked before streaming
final userLocationProvider = StreamProvider<Position?>((ref) async* {
  // Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint('📍 Location services are disabled');
    yield null;
    return;
  }

  // Check and request permissions
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('📍 Location permission denied');
      yield null;
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    debugPrint('📍 Location permission permanently denied');
    yield null;
    return;
  }

  // Get initial position immediately
  try {
    final initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    debugPrint(
      '📍 Initial position: ${initialPosition.latitude}, ${initialPosition.longitude}',
    );
    yield initialPosition;
  } catch (e) {
    debugPrint('📍 Error getting initial position: $e');
  }

  // Then stream updates
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters for more responsive tracking
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

/// Device heading from magnetometer (compass sensor)
final deviceHeadingProvider = StreamProvider<double>((ref) {
  return FlutterCompass.events!.map((event) => event.heading ?? 0);
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
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
    final locationState = ref.watch(userLocationProvider);
    final bearing = ref.watch(bearingToWorkshopProvider);
    final distance = ref.watch(distanceToWorkshopProvider);
    final deviceHeading = ref.watch(deviceHeadingProvider).valueOrNull ?? 0;

    final hasLocation = locationState.valueOrNull != null;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      showGlow: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.near_me, color: TalayTheme.primaryCyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'Talay Atölye',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TalayTheme.primaryCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140, // Reverted to smaller size as requested
            width: double.infinity,
            child: locationState.when(
              data: (position) => position != null
                  ? _CompassWidget(
                      targetBearing: bearing,
                      deviceHeading: deviceHeading,
                      distance: distance,
                    )
                  : _buildLocationDisabled(),
              loading: () => const Center(
                child: CircularProgressIndicator(color: TalayTheme.primaryCyan),
              ),
              error: (_, __) => _buildLocationDisabled(),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: TalayTheme.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDistance(distance),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TalayTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
          onPressed: () {
            // Invalidate provider to retry permission check and location
            ref.invalidate(userLocationProvider);
          },
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

/// Compass widget that points toward the workshop using device heading
/// The key formula: relativeBearing = targetBearing - deviceHeading
/// This makes the arrow physically point toward the target as you rotate the phone
class _CompassWidget extends StatefulWidget {
  final double targetBearing;
  final double deviceHeading;
  final double distance;

  const _CompassWidget({
    required this.targetBearing,
    required this.deviceHeading,
    required this.distance,
  });

  @override
  State<_CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<_CompassWidget>
    with SingleTickerProviderStateMixin {
  // Low Pass Filter for smoothing sensor data
  final _filter = _LowPassFilter(
    alpha: 0.1,
  ); // alpha 0.1 means 90% old data, 10% new
  double _filteredHeading = 0;

  /// Normalize angle to [-180, 180] for shortest path rotation
  double _normalizeAngle(double angle) {
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;
    return angle;
  }

  @override
  void didUpdateWidget(_CompassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Apply low pass filter to smoothen the device heading
    _filteredHeading = _filter.filter(widget.deviceHeading);
  }

  @override
  void initState() {
    super.initState();
    _filteredHeading = widget.deviceHeading;
  }

  String _getDirectionText(double relativeAngle) {
    final angle = _normalizeAngle(relativeAngle);
    if (angle.abs() < 20) return 'Tam Karşınızda';
    if (angle.abs() > 160) return 'Arkanızda';
    if (angle > 0) return 'Sağınızda';
    return 'Solunuzda';
  }

  @override
  Widget build(BuildContext context) {
    // Relative bearing = Target (Fixed) - Device (Dynamic Filtered)
    final relativeAngle = _normalizeAngle(
      widget.targetBearing - _filteredHeading,
    );

    final arrowRad = relativeAngle * math.pi / 180;

    // Ring doesn't rotate - North is always "UP" on the phone screen
    const ringRad = 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Static compass ring
            Transform.rotate(
              angle: ringRad,
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _CompassRingPainter(),
              ),
            ),
            // Arrow pointing to workshop (relative to device heading)
            Transform.rotate(
              angle: arrowRad,
              child: SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(painter: _ArrowPainter()),
              ),
            ),
            // Center dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: TalayTheme.background,
                shape: BoxShape.circle,
                border: Border.all(color: TalayTheme.primaryCyan, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: TalayTheme.primaryCyan.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Direction text only visible when close (<= 5 meters)
        if (widget.distance <= 5)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: TalayTheme.primaryCyan,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: TalayTheme.primaryCyan.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _getDirectionText(relativeAngle),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          )
        else
          const SizedBox(height: 34),
      ],
    );
  }
}

class _LowPassFilter {
  final double alpha;
  double? _lastValue;

  _LowPassFilter({this.alpha = 0.2});

  double filter(double input) {
    if (_lastValue == null) {
      _lastValue = input;
      return input;
    }

    // Handle wrap-around for angles (0 <-> 360)
    double diff = input - _lastValue!;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    _lastValue = _lastValue! + alpha * diff;

    // Normalize result to 0-360
    if (_lastValue! > 360) _lastValue = _lastValue! - 360;
    if (_lastValue! < 0) _lastValue = _lastValue! + 360;

    return _lastValue!;
  }
}

/// Paints the directional arrow pointing to target
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Modern sleek arrow design
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TalayTheme.primaryCyan,
          TalayTheme.primaryCyan.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 40))
      ..style = PaintingStyle.fill;

    final path = Path();
    // Tip
    path.moveTo(center.dx, center.dy - 35);
    // Right wing
    path.lineTo(center.dx + 12, center.dy + 15);
    // Center notch
    path.lineTo(center.dx, center.dy + 5);
    // Left wing
    path.lineTo(center.dx - 12, center.dy + 15);
    path.close();

    // Draw shadow
    canvas.drawShadow(
      path,
      TalayTheme.primaryCyan.withValues(alpha: 0.5),
      6,
      true,
    );

    // Draw main arrow
    canvas.drawPath(path, paint);

    // Optional: Add a small white accent at the tip
    final tipPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final tipPath = Path()
      ..moveTo(center.dx, center.dy - 35)
      ..lineTo(center.dx + 4, center.dy - 20)
      ..lineTo(center.dx - 4, center.dy - 20)
      ..close();

    canvas.drawPath(tipPath, tipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    // Background circle
    final bgPaint = Paint()
      ..color = TalayTheme.primaryCyan.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = TalayTheme.primaryCyan.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, ringPaint);

    // Tick marks - Static frame
    for (int i = 0; i < 36; i++) {
      final angle = (i * 10 - 90) * math.pi / 180;
      final isCardinal = i % 9 == 0; // Every 90°
      final isMajor = i % 3 == 0; // Every 30°

      final outerR = radius - 5;
      final innerR = isCardinal
          ? radius - 15
          : (isMajor ? radius - 10 : radius - 7);

      final x1 = center.dx + outerR * math.cos(angle);
      final y1 = center.dy + outerR * math.sin(angle);
      final x2 = center.dx + innerR * math.cos(angle);
      final y2 = center.dy + innerR * math.sin(angle);

      final tickPaint = Paint()
        ..color = isCardinal
            ? TalayTheme.primaryCyan.withOpacity(0.8)
            : (isMajor
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(0.15))
        ..strokeWidth = isCardinal ? 2 : (isMajor ? 1.5 : 0.8)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // Draw "Telefona Göre" label at bottom
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TELEFON YÖNÜ',
        style: TextStyle(
          color: TalayTheme.textSecondary.withOpacity(0.5),
          fontSize: 8,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + radius / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
