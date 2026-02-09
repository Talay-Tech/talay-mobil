import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../talay_theme.dart';
import '../models/countdown_model.dart';
import '../services/countdown_service.dart';

/// Countdown Timer Widget
///
/// Ana sayfanın en üstünde gösterilen geri sayım widget'ı.
/// Admin panelden yönetilen başlık, alt başlık ve hedef tarih içerir.
class CountdownWidget extends ConsumerStatefulWidget {
  const CountdownWidget({super.key});

  @override
  ConsumerState<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends ConsumerState<CountdownWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(countdownSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (settings == null || !settings.isActive) {
          return const SizedBox.shrink();
        }
        return _buildCountdownCard(context, settings);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCountdownCard(BuildContext context, CountdownSettings settings) {
    final remaining = settings.getRemainingTime();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TalayTheme.primaryCyan.withValues(alpha: 0.15),
                TalayTheme.secondaryPurple.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: TalayTheme.primaryCyan.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ana Başlık
              Text(
                settings.mainTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: TalayTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              // Alt Başlık
              if (settings.subTitle != null &&
                  settings.subTitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  settings.subTitle!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TalayTheme.primaryCyan,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),

              // Geri Sayım veya Süre Doldu Mesajı
              if (remaining.isExpired)
                _buildExpiredMessage(context, settings.expiredMessage)
              else
                _buildTimeDisplay(context, remaining),

              // Açıklama
              if (settings.description != null &&
                  settings.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  settings.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TalayTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context, RemainingTime remaining) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeUnit(context, remaining.years.toString(), 'YIL'),
        _buildDivider(),
        _buildTimeUnit(context, remaining.months.toString(), 'AY'),
        _buildDivider(),
        _buildTimeUnit(context, remaining.days.toString(), 'GÜN'),
        _buildDivider(),
        _buildTimeUnit(
          context,
          remaining.hours.toString().padLeft(2, '0'),
          'SAAT',
        ),
      ],
    );
  }

  Widget _buildTimeUnit(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TalayTheme.primaryCyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: TalayTheme.primaryCyan,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: TalayTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: TalayTheme.primaryCyan.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildExpiredMessage(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: TalayTheme.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TalayTheme.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_outlined, color: TalayTheme.success, size: 28),
          const SizedBox(width: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: TalayTheme.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
