import 'dart:ui';
import 'package:flutter/material.dart';

import '../talay_theme.dart';
import '../models/app_update_model.dart';
import '../services/update_service.dart';

/// Güncelleme bildirimi dialog'u
///
/// Zorunlu güncellemelerde kapatılamaz, sadece güncelleme butonu gösterilir.
/// Opsiyonel güncellemelerde "Şimdi Güncelle" ve "Sonra" seçenekleri vardır.
class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onSkip;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersion,
    this.onSkip,
  });

  /// Dialog'u göster
  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    required String currentVersion,
    VoidCallback? onSkip,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        currentVersion: currentVersion,
        onSkip: onSkip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.forceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İkon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TalayTheme.primaryCyan.withValues(alpha: 0.3),
                          TalayTheme.secondaryPurple.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 48,
                      color: TalayTheme.primaryCyan,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık
                  Text(
                    updateInfo.forceUpdate
                        ? 'Zorunlu Güncelleme'
                        : 'Yeni Güncelleme Mevcut!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TalayTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Sürüm bilgisi
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TalayTheme.primaryCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: TalayTheme.primaryCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'v$currentVersion → v${updateInfo.latestVersion}',
                      style: const TextStyle(
                        color: TalayTheme.primaryCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Release Notes
                  if (updateInfo.releaseNotes.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Yenilikler:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: TalayTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Text(
                          updateInfo.releaseNotes,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: TalayTheme.textPrimary.withValues(
                                  alpha: 0.9,
                                ),
                                height: 1.5,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Güncelle butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await UpdateService.openDownloadUrl(
                          updateInfo.apkDownloadUrl,
                        );
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('İndirme bağlantısı açılamadı'),
                              backgroundColor: TalayTheme.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Şimdi Güncelle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TalayTheme.primaryCyan,
                        foregroundColor: TalayTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Sonra butonu (sadece opsiyonel için)
                  if (!updateInfo.forceUpdate) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          onSkip?.call();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TalayTheme.textSecondary,
                          side: BorderSide(
                            color: TalayTheme.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Sonra Hatırlat'),
                      ),
                    ),
                  ],

                  // Zorunlu güncelleme uyarısı
                  if (updateInfo.forceUpdate) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: TalayTheme.warning.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bu güncelleme zorunludur',
                          style: TextStyle(
                            color: TalayTheme.warning.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
