// lib/utils/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService();
  static final instance = NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Android
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS (Darwin)
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    // ← ここでawaitする（例外は上に投げる or 捕まえる）
    await _plugin.initialize(
      settings,
      // 通知タップ時コールバック（必要なければ省略可）
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        // TODO: 画面遷移など
      },
      // バックグラウンドからのタップ（必要なら）
      // onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // サンプル: 即時通知
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel', 'General',
      importance: Importance.max, priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(id, title, body, details);
  }
}

// （バックグラウンドタップ使う場合はトップレベル関数が必要）
// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse r) { /* ... */ }
