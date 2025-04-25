import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:guerrero_barber_app/screens/screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Supabase primero
    await Supabase.initialize(
      url: 'https://sevejjaoodnjhzrjthuv.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNldmVqamFvb2Ruamh6cmp0aHV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1MTE1MDQsImV4cCI6MjA2MTA4NzUwNH0.jCaLdbclZ567DHxFlSK1_Aadrry6hdxT4m8p_U8IO_I'
    );

    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Solicitar permisos en Android
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.request();
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      
      if (notificationStatus.isDenied || alarmStatus.isDenied) {
        print('Permisos de notificación o alarma denegados');
        // Aquí podrías mostrar un diálogo explicando por qué se necesitan los permisos
      }
    }

    // Inicializar notificaciones
    final notificationsService = NotificationsService();
    if (!notificationsService.isInitialized) {
      await notificationsService.initNotification();
    }

    // Inicializar AndroidAlarmManager
    await AndroidAlarmManager.initialize();

    // Programar tarea periódica
    await AndroidAlarmManager.periodic(
      const Duration(hours: 1),
      0,
      NotificationsService.checkPendingAppointments,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  } catch (e) {
    print('Error durante la inicialización: $e');
    rethrow;
  }
}

void main() async {
  try {
    await initializeApp();
    runApp(const MyApp());
  } catch (e) {
    print('Error al iniciar la aplicación: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al iniciar la aplicación',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await initializeApp();
                    if (context.mounted) {
                      runApp(const MyApp());
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
