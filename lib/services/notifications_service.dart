import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:guerrero_barber_app/services/device_token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        try {
          await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=BLfl2TrjL6juJ49ol1Ks8iu3x0iB5djXAu0q5kOsVHcKI6dwTzHqf2UlCcuSYzkO7pDgmR5AWAt6hYKIG7aVXQk', // Reemplaza con tu clave de servidor FCM
            },
            body: json.encode({
              'to': token,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            }),
          );
        } catch (e) {
          print('Error al enviar notificación al token $token: $e');
        }
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

  // Método específico para notificar sobre citas pendientes
  Future<void> notifyPendingAppointment() async {
    try {
      final List<String> adminTokens = await _deviceTokenService.getAllAdminDeviceTokens();
      
      if (adminTokens.isEmpty) {
        print('No hay tokens de administradores disponibles');
        return;
      }

      const title = "Citas Pendientes";
      const body = "Tienes citas pendientes por aprobar";
      
      for (String token in adminTokens) {
        try {
          // Enviar mensaje FCM
          await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=BLfl2TrjL6juJ49ol1Ks8iu3x0iB5djXAu0q5kOsVHcKI6dwTzHqf2UlCcuSYzkO7pDgmR5AWAt6hYKIG7aVXQk', // Reemplaza con tu clave de servidor FCM
            },
            body: json.encode({
              'to': token,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'type': 'pending_appointment',
              },
            }),
          );

          // También mostrar una notificación local
          await showNotification(
            title: title,
            body: body,
            appointmentTime: DateTime.now(),
            scheduledTime: DateTime.now(),
          );
        } catch (tokenError) {
          print('Error al enviar notificación al token $token: $tokenError');
          continue;
        }
      }
    } catch (e) {
      print('Error al enviar notificación de cita pendiente: $e');
      rethrow;
    }
  }

  // Método para notificar al cliente que su cita ha sido aceptada
  Future<void> notifyAppointmentAccepted({
    required String userId,
    required DateTime appointmentTime,
  }) async {
    try {
      final List<String> userTokens = await _deviceTokenService.getUserDeviceTokens(userId);
      
      if (userTokens.isEmpty) {
        print('No hay tokens disponibles para el usuario $userId');
        return;
      }

      final String formattedDate = "${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}";
      final String formattedTime = "${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}";
      
      const title = "¡Cita Confirmada!";
      final body = "Tu cita para el $formattedDate a las $formattedTime ha sido confirmada";
      
      for (String token in userTokens) {
        try {
          // Enviar mensaje FCM
          await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=BLfl2TrjL6juJ49ol1Ks8iu3x0iB5djXAu0q5kOsVHcKI6dwTzHqf2UlCcuSYzkO7pDgmR5AWAt6hYKIG7aVXQk', // Reemplaza con tu clave de servidor FCM
            },
            body: json.encode({
              'to': token,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'type': 'appointment_accepted',
                'appointment_time': appointmentTime.toIso8601String(),
              },
            }),
          );

          // También mostrar una notificación local
          await showNotification(
            title: title,
            body: body,
            appointmentTime: appointmentTime,
            scheduledTime: DateTime.now(),
          );
        } catch (tokenError) {
          print('Error al enviar notificación al token $token: $tokenError');
          continue;
        }
      }
    } catch (e) {
      print('Error al enviar notificación de cita aceptada: $e');
      rethrow;
    }
  }

  // Método estático para verificar citas pendientes (llamado por AndroidAlarmManager)
  @pragma('vm:entry-point')
  static Future<void> checkPendingAppointments() async {
    try {
      final notificationsService = NotificationsService();
      await notificationsService.initNotification();
      await notificationsService.notifyPendingAppointment();
    } catch (e) {
      print('Error al verificar citas pendientes: $e');
    }
  }
}
