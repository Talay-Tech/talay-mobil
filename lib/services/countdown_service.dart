/// Countdown Service
///
/// Zamanlayıcı verilerini yöneten servis.
/// Supabase'den ayarları çeker ve gerçek zamanlı güncelleme sağlar.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/countdown_model.dart';
import 'auth_service.dart';

/// Countdown ayarlarını çeken provider
final countdownSettingsProvider = FutureProvider<CountdownSettings?>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    final response = await client
        .from('countdown_settings')
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return CountdownSettings.fromJson(response);
  } catch (e) {
    return null;
  }
});

/// Kalan süreyi gerçek zamanlı güncelleyen provider
/// Her saniye güncellenir
final countdownTimerProvider =
    StreamProvider.family<RemainingTime?, CountdownSettings?>((ref, settings) {
      if (settings == null) {
        return Stream.value(null);
      }

      return Stream.periodic(const Duration(seconds: 1), (_) {
        return settings.getRemainingTime();
      });
    });

/// Countdown servis sınıfı (admin işlemleri için)
class CountdownService {
  final SupabaseClient _client;

  CountdownService(this._client);

  /// Yeni countdown ayarı oluştur
  Future<void> createSettings({
    required String mainTitle,
    String? subTitle,
    String? description,
    required DateTime targetDate,
    String expiredMessage = 'Süre doldu',
    bool isActive = true,
  }) async {
    await _client.from('countdown_settings').insert({
      'main_title': mainTitle,
      'sub_title': subTitle,
      'description': description,
      'target_date': targetDate.toIso8601String(),
      'expired_message': expiredMessage,
      'is_active': isActive,
    });
  }

  /// Countdown ayarlarını güncelle
  Future<void> updateSettings({
    required String id,
    String? mainTitle,
    String? subTitle,
    String? description,
    DateTime? targetDate,
    String? expiredMessage,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};

    if (mainTitle != null) updates['main_title'] = mainTitle;
    if (subTitle != null) updates['sub_title'] = subTitle;
    if (description != null) updates['description'] = description;
    if (targetDate != null)
      updates['target_date'] = targetDate.toIso8601String();
    if (expiredMessage != null) updates['expired_message'] = expiredMessage;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isNotEmpty) {
      await _client.from('countdown_settings').update(updates).eq('id', id);
    }
  }

  /// Countdown ayarlarını sil
  Future<void> deleteSettings(String id) async {
    await _client.from('countdown_settings').delete().eq('id', id);
  }
}

/// Countdown servis provider
final countdownServiceProvider = Provider<CountdownService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CountdownService(client);
});
