import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationsService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Inicializa las zonas horarias.
    tz.initializeTimeZones();

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationsPlugin.initialize(initSettings);

    // Solicita permisos en iOS.
    await notificationsPlugin
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

  /// Muestra una notificación programada para 2 horas antes de la cita.
  Future<void> showNotification({
    required DateTime appointmentTime,
    int id = 0,
    String? title,
    String? body,
  }) async {
    // La notificación se programará 2 horas antes de la cita.
    final scheduledTime = appointmentTime.subtract(const Duration(hours: 3));
    // Si la hora programada es anterior a ahora, se omite la programación.
    if (scheduledTime.isBefore(DateTime.now())) return;

    await notificationsPlugin.zonedSchedule(
      id,
      title ?? 'Recordatorio de cita',
      body ??
          'Tienes una cita a las ${DateFormat('HH:mm').format(appointmentTime)}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
