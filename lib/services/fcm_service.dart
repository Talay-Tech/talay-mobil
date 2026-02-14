import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: the system tray notification is shown automatically.
  // If you need to do background work, add it here.
}

/// Riverpod provider for [FcmService].
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ──────────────────────────────────────────────
  //  Android notification channel
  // ──────────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'talay_notifications', // channel id
    'Talay Bildirimler', // channel name
    description: 'Talay uygulaması bildirimleri',
    importance: Importance.high,
  );

  // ──────────────────────────────────────────────
  //  Initialization
  // ──────────────────────────────────────────────
  Future<void> initialize() async {
    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permission (Android 13+ & iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User denied — nothing more to do.
    }

    // Create the high-importance Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Initialize flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Listen for when user taps a background/terminated notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Handle the case where the app was opened from a terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    // Get and store the FCM token
    await _saveToken();

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((_) => _saveToken());
  }

  // ──────────────────────────────────────────────
  //  Foreground notification display
  // ──────────────────────────────────────────────
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Notification tap handlers
  // ──────────────────────────────────────────────
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate based on payload if needed
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    // TODO: Navigate based on message data if needed
  }

  // ──────────────────────────────────────────────
  //  Token management
  // ──────────────────────────────────────────────
  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final platform = Platform.isAndroid ? 'android' : 'ios';

      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      // Silently fail — token will be retried on next refresh.
    }
  }

  /// Removes the stored FCM token (call on logout).
  Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('token', token);
    } catch (_) {}
  }
}
