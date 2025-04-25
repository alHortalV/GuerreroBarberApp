import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:guerrero_barber_app/services/device_token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:guerrero_barber_app/config/firebase_config.dart';
import 'package:guerrero_barber_app/services/oauth2_service.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DeviceTokenService _deviceTokenService = DeviceTokenService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  Future<void> initNotification() async {
    if (_isInitialized) return;

    // Asegurarse de que Firebase esté inicializado
    await Firebase.initializeApp();

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

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar la respuesta de la notificación cuando la app está en primer plano
        print('Notificación recibida en primer plano: ${response.payload}');
      },
    );

    // Solicitar permisos de notificación
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar manejadores de mensajes de Firebase
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Obtener el token FCM actual
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Configurar la actualización del token
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      print('Token actualizado: $token');
      _deviceTokenService.registerDeviceToken();
    });

    _isInitialized = true;
  }

  // Manejador de mensajes en primer plano
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Mensaje recibido en primer plano: ${message.messageId}');
    
    // Mostrar notificación local
    await showNotification(
      title: message.notification?.title ?? 'Nueva notificación',
      body: message.notification?.body ?? '',
      appointmentTime: DateTime.now(),
      scheduledTime: DateTime.now(),
    );
  }

  // Manejador cuando se abre una notificación con la app en segundo plano
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Notificación abierta desde segundo plano: ${message.messageId}');
  }

  // Manejador de mensajes en segundo plano
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
  }

  // Enviar notificación a todos los dispositivos de administrador
  Future<void> sendAdminNotification({
    required String title,
    required String body,
  }) async {
    try {
      final List<String> adminTokens = await _deviceTokenService.getAllAdminDeviceTokens();
      
      if (adminTokens.isEmpty) {
        print('No hay tokens de administradores disponibles');
        return;
      }

      // Obtener el token de acceso OAuth2
      final accessToken = await OAuth2Service.getAccessToken();

      for (final token in adminTokens) {
        final response = await http.post(
          Uri.parse(FirebaseConfig.fcmBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: json.encode({
            'message': {
              'token': token,
              'notification': {
                'title': title,
                'body': body
              },
              'android': {
                'notification': {
                  'channel_id': 'citas_channel',
                  'priority': 'high'
                }
              },
              'apns': {
                'payload': {
                  'aps': {
                    'sound': 'default',
                    'badge': 1
                  }
                }
              }
            }
          }),
        );

        if (response.statusCode != 200) {
          print('Error al enviar notificación. Código: ${response.statusCode}');
          print('Respuesta: ${response.body}');
        } else {
          print('Notificación enviada exitosamente al administrador con token: $token');
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
      
      final accessToken = await OAuth2Service.getAccessToken();

      for (final token in adminTokens) {
        final response = await http.post(
          Uri.parse(FirebaseConfig.fcmBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: json.encode({
            'message': {
              'token': token,
              'notification': {
                'title': title,
                'body': body
              },
              'android': {
                'priority': 'HIGH',
                'notification': {
                  'channel_id': 'citas_channel',
                  'notification_priority': 'PRIORITY_HIGH'
                }
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'type': 'pending_appointment',
              }
            }
          }),
        );

        if (response.statusCode != 200) {
          print('Error al enviar notificación. Código: ${response.statusCode}');
          print('Respuesta: ${response.body}');
        } else {
          print('Notificación enviada exitosamente al administrador con token: $token');
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
      final userToken = await _deviceTokenService.getUserLastDeviceToken(userId);
      
      if (userToken == null) {
        print('No hay token disponible para el usuario $userId');
        return;
      }

      final String formattedDate = "${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}";
      final String formattedTime = "${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}";
      
      const title = "¡Cita Confirmada!";
      final body = "Tu cita para el $formattedDate a las $formattedTime ha sido confirmada";
      
      final accessToken = await OAuth2Service.getAccessToken();

      final response = await http.post(
        Uri.parse(FirebaseConfig.fcmBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'token': userToken,
            'notification': {
              'title': title,
              'body': body
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'channel_id': 'citas_channel',
                'notification_priority': 'PRIORITY_HIGH'
              }
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'type': 'appointment_accepted',
              'appointment_time': appointmentTime.toIso8601String(),
            }
          }
        }),
      );

      if (response.statusCode != 200) {
        print('Error al enviar notificación. Código: ${response.statusCode}');
        print('Respuesta: ${response.body}');
      } else {
        print('Notificación enviada exitosamente al usuario $userId');
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

  Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final accessToken = await OAuth2Service.getAccessToken();

      final response = await http.post(
        Uri.parse(FirebaseConfig.fcmBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'channel_id': 'citas_channel',
                'notification_priority': 'PRIORITY_HIGH'
              }
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al enviar notificación: ${response.body}');
      }
    } catch (e) {
      print('Error en sendNotification: $e');
      throw Exception('Error al enviar la notificación: $e');
    }
  }
}
