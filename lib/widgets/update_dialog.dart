import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../talay_theme.dart';
import '../models/app_update_model.dart';
import '../services/update_service.dart';

/// Güncelleme bildirimi dialog'u
///
/// Zorunlu güncellemelerde kapatılamaz, sadece güncelleme butonu gösterilir.
/// Opsiyonel güncellemelerde "Şimdi Güncelle" ve "Sonra" seçenekleri vardır.
/// İndirme ilerleme durumunu progress bar ile gösterir.
class UpdateDialog extends StatefulWidget {
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
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  int _downloadProgress = 0;
  String _statusText = '';
  String? _errorText;
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _statusText = 'İndirme başlatılıyor...';
      _errorText = null;
    });

    _otaSubscription =
        UpdateService.downloadAndInstallApk(
          widget.updateInfo.apkDownloadUrl,
        ).listen(
          (OtaEvent event) {
            if (!mounted) return;
            setState(() {
              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  _downloadProgress = int.tryParse(event.value ?? '0') ?? 0;
                  _statusText = 'İndiriliyor... %$_downloadProgress';
                  break;
                case OtaStatus.INSTALLING:
                  _statusText = 'Kurulum başlatılıyor...';
                  _downloadProgress = 100;
                  break;
                case OtaStatus.ALREADY_RUNNING_ERROR:
                  _errorText = 'Güncelleme zaten çalışıyor';
                  _isDownloading = false;
                  break;
                case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                  _errorText =
                      'Kurulum izni verilmedi.\nAyarlar > Bilinmeyen kaynaklar izni verin.';
                  _isDownloading = false;
                  break;
                case OtaStatus.INTERNAL_ERROR:
                  _errorText = 'İndirme hatası oluştu';
                  _isDownloading = false;
                  break;
                case OtaStatus.DOWNLOAD_ERROR:
                  _errorText =
                      'İndirme başarısız oldu.\nİnternet bağlantınızı kontrol edin.';
                  _isDownloading = false;
                  break;
                case OtaStatus.CHECKSUM_ERROR:
                  _errorText = 'Dosya doğrulama hatası';
                  _isDownloading = false;
                  break;
              }
            });
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              _errorText = 'Güncelleme hatası: $e';
              _isDownloading = false;
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.updateInfo.forceUpdate && !_isDownloading,
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
                    child: Icon(
                      _isDownloading
                          ? Icons.downloading_rounded
                          : Icons.system_update_rounded,
                      size: 48,
                      color: TalayTheme.primaryCyan,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık
                  Text(
                    _isDownloading
                        ? 'Güncelleme İndiriliyor'
                        : widget.updateInfo.forceUpdate
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
                      'v${widget.currentVersion} → v${widget.updateInfo.latestVersion}',
                      style: const TextStyle(
                        color: TalayTheme.primaryCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // İndirme durumunda: Progress bar
                  if (_isDownloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _downloadProgress / 100,
                        minHeight: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          TalayTheme.primaryCyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: TalayTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],

                  // Hata mesajı
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TalayTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TalayTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _errorText!,
                        style: TextStyle(color: TalayTheme.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // İndirme devam etmiyorken: Release Notes
                  if (!_isDownloading &&
                      widget.updateInfo.releaseNotes.isNotEmpty) ...[
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
                          widget.updateInfo.releaseNotes,
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

                  // Güncelle / Tekrar Dene butonu
                  if (!_isDownloading) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startDownload,
                        icon: Icon(
                          _errorText != null
                              ? Icons.refresh_rounded
                              : Icons.download_rounded,
                        ),
                        label: Text(
                          _errorText != null ? 'Tekrar Dene' : 'Şimdi Güncelle',
                        ),
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
                  ],

                  // Sonra butonu (sadece opsiyonel ve indirme yokken)
                  if (!widget.updateInfo.forceUpdate && !_isDownloading) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onSkip?.call();
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
                  if (widget.updateInfo.forceUpdate && !_isDownloading) ...[
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
