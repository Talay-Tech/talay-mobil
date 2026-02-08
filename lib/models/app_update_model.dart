/// App Update Model
///
/// Sunucudan gelen güncelleme bilgilerini temsil eder.
/// Zorunlu veya opsiyonel güncelleme durumlarını destekler.

class AppUpdateInfo {
  final String latestVersion;
  final bool forceUpdate;
  final String apkDownloadUrl;
  final String releaseNotes;
  final DateTime? releaseDate;
  final int? minBuildNumber;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.forceUpdate,
    required this.apkDownloadUrl,
    required this.releaseNotes,
    this.releaseDate,
    this.minBuildNumber,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String,
      forceUpdate: json['force_update'] as bool? ?? false,
      apkDownloadUrl: json['apk_download_url'] as String,
      releaseNotes: json['release_notes'] as String? ?? '',
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'] as String)
          : null,
      minBuildNumber: json['min_build_number'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'force_update': forceUpdate,
      'apk_download_url': apkDownloadUrl,
      'release_notes': releaseNotes,
      'release_date': releaseDate?.toIso8601String(),
      'min_build_number': minBuildNumber,
    };
  }

  @override
  String toString() {
    return 'AppUpdateInfo(latestVersion: $latestVersion, forceUpdate: $forceUpdate)';
  }
}

/// Güncelleme durumunu temsil eden enum
enum UpdateStatus {
  /// Güncelleme kontrolü yapılıyor
  checking,

  /// Güncelleme mevcut
  updateAvailable,

  /// Uygulama güncel
  upToDate,

  /// Hata oluştu
  error,
}

/// Güncelleme kontrol sonucu
class UpdateCheckResult {
  final UpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.status,
    this.updateInfo,
    this.errorMessage,
  });

  factory UpdateCheckResult.checking() {
    return const UpdateCheckResult(status: UpdateStatus.checking);
  }

  factory UpdateCheckResult.upToDate() {
    return const UpdateCheckResult(status: UpdateStatus.upToDate);
  }

  factory UpdateCheckResult.available(AppUpdateInfo info) {
    return UpdateCheckResult(
      status: UpdateStatus.updateAvailable,
      updateInfo: info,
    );
  }

  factory UpdateCheckResult.error(String message) {
    return UpdateCheckResult(status: UpdateStatus.error, errorMessage: message);
  }

  bool get hasUpdate =>
      status == UpdateStatus.updateAvailable && updateInfo != null;
  bool get isForceUpdate => hasUpdate && updateInfo!.forceUpdate;
}
