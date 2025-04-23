import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'background_tasks.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Solicita permiso para notificaciones si es Android
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }
  
  await NotificationsService().initNotification();
  await AndroidAlarmManager.initialize();

  // Programa la tarea periódica: se ejecuta cada 15 minutos
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 5),
    0, // ID único para la tarea
    checkAppointmentsCallback,
    wakeup: true,
    rescheduleOnReboot: false,
  );

  runApp(const MyApp());
}

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