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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:guerrero_barber_app/screens/screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase primero
  await Supabase.initialize(
      url: 'https://sevejjaoodnjhzrjthuv.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNldmVqamFvb2Ruamh6cmp0aHV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1MTE1MDQsImV4cCI6MjA2MTA4NzUwNH0.jCaLdbclZ567DHxFlSK1_Aadrry6hdxT4m8p_U8IO_I');

  // Inicializar Firebase después
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Solicitar permisos necesarios
  if (Platform.isAndroid) {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  // Inicializar el servicio de notificaciones
  await NotificationsService().initNotification();

  // Inicializar AndroidAlarmManager
  await AndroidAlarmManager.initialize();

  // Programa la tarea periódica: se ejecuta cada 1 minuto
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 1),
    0, // ID único para la tarea
    checkAppointmentsCallback,
    wakeup: true,
    rescheduleOnReboot: true,
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
