import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Solicita permiso para notificaciones en Android 13+
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  await NotificationsService().initNotification();

  // Inicializa Workmanager (para debug, isInDebugMode: true)
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  
  // Registra una tarea periódica (cada 15 minutos, por ejemplo)
  Workmanager().registerPeriodicTask(
    "checkAppointmentsTask", // ID único para la tarea
    "checkAppointments",      // nombre de la tarea
    frequency: const Duration(minutes: 10),
  );

  runApp(const MyApp());
}

/// La función que se ejecutará en segundo plano
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Consulta los datos de citas pendientes (por ejemplo, a futuro)
    final now = DateTime.now();
    final querySnapshot = await FirebaseFirestore.instance
        .collection("appointments")
        .where("dateTime", isGreaterThanOrEqualTo: now.toIso8601String())
        .orderBy("dateTime")
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      // Obtén la cita próxima
      final nextAppointmentData = querySnapshot.docs.first.data();
      final appointmentTime = DateTime.parse(nextAppointmentData["dateTime"]);
      
      // Calcula el momento de notificación: 3 horas antes
      final notificationMoment = appointmentTime.subtract(const Duration(hours: 3));
      
      // Si éste es un momento futuro, programa la notificación.
      final tz.TZDateTime tzNotificationTime = notificationMoment.isBefore(DateTime.now())
          ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1))
          : tz.TZDateTime.from(notificationMoment, tz.local);

      // Programa la notificación usando tu servicio
      await NotificationsService().showNotification(
        appointmentTime: appointmentTime,
        title: 'Recordatorio de cita',
        body: 'Tienes una cita a las ${DateFormat("HH:mm").format(appointmentTime)}',
      );
    }
    
    // Retorna true para indicar que la tarea finalizó correctamente
    return Future.value(true);
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Guerrero Barber App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}