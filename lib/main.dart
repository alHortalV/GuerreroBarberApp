import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guerrero_barber_app/config/supabase_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guerrero_barber_app/services/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:guerrero_barber_app/widgets/widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Supabase primero
    await Supabase.initialize(
      url: SupabaseConfig.fromEnv().url,
      anonKey: SupabaseConfig.fromEnv().anonKey,
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
    await dotenv.load();
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationsService _notificationsService = NotificationsService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      if (!_notificationsService.isInitialized) {
        await _notificationsService.initNotification();
      }
    } catch (e) {
      print('Error al inicializar las notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
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
          themeMode: themeMode,
          builder: (context, child) {
            _notificationsService.updateContext(context);
            return child ?? const SizedBox.shrink();
          },
          home: StreamBuilder<firebase_auth.User?>(
            stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
            builder: (BuildContext context,
                AsyncSnapshot<firebase_auth.User?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (!snapshot.hasData) {
                return const AuthScreen();
              }

              // Si el usuario está autenticado, verificamos si es admin
              return StreamBuilder<bool>(
                stream: AdminService().adminStateChanges(),
                builder: (context, adminSnapshot) {
                  if (adminSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SplashScreen();
                  }

                  // Si es admin, mostramos el panel de admin
                  if (adminSnapshot.data == true) {
                    return const AdminPanel();
                  }

                  // Si no es admin, mostramos la pantalla normal con el checker de citas canceladas
                  return CheckCancelledAppointments(
                    child: const HomeScreen(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
