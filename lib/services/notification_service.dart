import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback for handling notification taps. Set by the app at startup.
  static void Function(String? payload)? onNotificationTap;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    const androidChannel = AndroidNotificationChannel(
      'medtrace_reminders',
      'Medication & Reminder Alerts',
      description: 'Notifications for medication and appointment reminders',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (onNotificationTap != null && payload != null) {
      onNotificationTap!(payload);
    }
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    if (!when.isAfter(DateTime.now())) return;

    final notificationPayload = payload ??
        jsonEncode({'type': 'reminder', 'route': '/patient/reminders'});

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'medtrace_reminders',
        'Medication & Reminder Alerts',
        channelDescription:
            'Notifications for medication and appointment reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: notificationPayload,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
