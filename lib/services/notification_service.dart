import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(settings);
  }

  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    await _plugin.cancel(0);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate =
          scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        0,
        '오늘 감정을 기록했나요? 📝',
        '하루를 돌아보며 감정을 기록해보세요.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            '매일 감정 기록 알림',
            channelDescription: '매일 감정 기록을 위한 알림이에요',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: IOSNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('알림 설정 실패: $e');
    }
  }

  Future<void> cancelNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(0);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}