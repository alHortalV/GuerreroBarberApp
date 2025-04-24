import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Inicializa las zonas horarias.
    tzData.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: initSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);

    // Solicita permisos en iOS.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _isInitialized = true;
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Convertir scheduledTime a TZDateTime usando la zona local
    tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Si el scheduledTime ya pasó, ajustarlo para programarlo unos segundos en el futuro
    if (tzScheduledTime.isBefore(now)) {
      tzScheduledTime = now.add(const Duration(seconds: 5));
    }

    // Programar la notificación usando AndroidAlarmManager para mayor confiabilidad
    await AndroidAlarmManager.oneShotAt(
      tzScheduledTime,
      id,
      _showNotification,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'title': title,
        'body': body,
      },
    );

    // También programar con flutter_local_notifications como respaldo
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'citas_channel',
          'Recordatorios de Citas',
          channelDescription: 'Notificaciones programadas para recordar citas',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _showNotification(int id, Map<String, dynamic>? params) async {
    if (params == null) return;

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'citas_channel',
      'Recordatorios de Citas',
      channelDescription: 'Notificaciones programadas para recordar citas',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      params['title'] as String,
      params['body'] as String,
      platformChannelSpecifics,
    );
  }

  // Si sigues usando showNotification para el background task, lo mantienes
  Future<void> showNotification({
    required DateTime appointmentTime,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    // Puedes llamar a scheduleNotification usando una id generada, por ejemplo:
    await scheduleNotification(
      id: appointmentTime.hashCode, // O usa otra lógica de id
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }
}
