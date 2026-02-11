/// Update Service
///
/// Uygulama güncellemelerini kontrol eden servis.
/// Sunucudan sürüm bilgisi çeker ve mevcut sürümle karşılaştırır.
/// OTA ile APK indirme ve otomatik kurulum desteği sağlar.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update_model.dart';

/// Güncelleme kontrolü için kullanılan URL
/// Talay-Tech GitHub repository'den sürüm bilgisi çekilir
const String _updateCheckUrl =
    'https://raw.githubusercontent.com/Talay-Tech/talay-mobil/main/app_version.json';

/// Uygulama bilgisi provider'ı
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Güncelleme kontrol servisi
class UpdateService {
  final String updateCheckUrl;

  UpdateService({this.updateCheckUrl = _updateCheckUrl});

  /// Sunucudan güncelleme bilgisini çeker
  Future<AppUpdateInfo?> fetchUpdateInfo() async {
    try {
      final response = await http
          .get(Uri.parse(updateCheckUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(json);
      }
      return null;
    } catch (e) {
      // Ağ hatası veya parse hatası - sessizce geç
      return null;
    }
  }

  /// İki sürümü karşılaştırır
  /// Döndürür: 1 = v1 > v2, -1 = v1 < v2, 0 = eşit
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // En uzun listeye göre karşılaştır
    final maxLength = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    return 0;
  }

  /// Güncelleme kontrolü yapar
  Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
    final updateInfo = await fetchUpdateInfo();

    if (updateInfo == null) {
      return UpdateCheckResult.upToDate(); // Hata durumunda güncel say
    }

    final comparison = compareVersions(
      updateInfo.latestVersion,
      currentVersion,
    );

    if (comparison > 0) {
      return UpdateCheckResult.available(updateInfo);
    }

    return UpdateCheckResult.upToDate();
  }

  /// APK'yı uygulama içinden indir ve otomatik kurulum başlat
  /// İlerleme durumunu stream olarak döndürür
  static Stream<OtaEvent> downloadAndInstallApk(String url) {
    try {
      return OtaUpdate().execute(url, destinationFilename: 'talay.apk');
    } catch (e) {
      rethrow;
    }
  }
}

/// Update service provider
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

/// Güncelleme kontrol sonucu provider'ı
final updateCheckResultProvider = FutureProvider<UpdateCheckResult>((
  ref,
) async {
  final updateService = ref.watch(updateServiceProvider);
  final packageInfo = await ref.watch(packageInfoProvider.future);

  return updateService.checkForUpdate(packageInfo.version);
});

/// Güncellemeyi atla durumu (kullanıcı "Sonra" dediğinde)
final skipUpdateProvider = StateProvider<bool>((ref) => false);
