import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:guerrero_barber_app/services/device_token_service.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DeviceTokenService _deviceTokenService = DeviceTokenService();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Inicializa las zonas horarias
    tzData.initializeTimeZones();

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuración para iOS
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

    // Configurar Firebase Messaging para notificaciones en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Solicitar permisos para iOS
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

  // Manejador de mensajes en segundo plano
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }

  // Enviar notificación a todos los dispositivos de administrador
  Future<void> sendAdminNotification({
    required String title,
    required String body,
  }) async {
    try {
      final List<String> adminTokens = await _deviceTokenService.getAllAdminDeviceTokens();
      
      for (String token in adminTokens) {
        await FirebaseMessaging.instance.sendMessage(
          to: token,
          data: {
            'title': title,
            'body': body,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );
      }
    } catch (e) {
      print('Error al enviar notificación a administradores: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Método para mostrar notificación inmediata
  Future<void> showNotification({
    required String title,
    required String body,
    required DateTime appointmentTime,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'citas_channel',
      'Recordatorios de Citas',
      channelDescription: 'Notificaciones programadas para recordar citas',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      appointmentTime.hashCode,
      title,
      body,
      platformDetails,
    );
  }
}
