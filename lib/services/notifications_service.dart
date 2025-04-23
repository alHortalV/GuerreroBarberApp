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

  /// Programa una notificación para la cita, calculando internamente 3 horas antes.
  Future<void> showNotification({
    required DateTime appointmentTime,
    DateTime? scheduledTime, // Nuevo parámetro opcional
    int id = 0,
    String? title,
    String? body,
  }) async {
    // Si se pasa scheduledTime, se usará; de lo contrario, se calcula por defecto (ej. 3h antes)
    final effectiveScheduledTime = scheduledTime ?? appointmentTime.subtract(const Duration(hours: 2));
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime notificationTime = effectiveScheduledTime.isBefore(now)
        ? now.add(const Duration(seconds: 1))
        : tz.TZDateTime.from(effectiveScheduledTime, tz.local);

    await notificationsPlugin.zonedSchedule(
      id,
      title ?? 'Recordatorio de cita',
      body ?? 'Tienes una cita a las ${DateFormat('HH:mm').format(appointmentTime)}',
      notificationTime,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
