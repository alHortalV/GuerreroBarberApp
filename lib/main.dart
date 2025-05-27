import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guerrero_barber_app/config/supabase_config.dart';
import 'package:guerrero_barber_app/services/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guerrero_barber_app/theme/theme.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:guerrero_barber_app/screens/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);
final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

Future<void> initializeApp() async {
  try {
    print('Inicializando Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.fromEnv().url,
      anonKey: SupabaseConfig.fromEnv().anonKey,
    );
    print('Supabase inicializado.');

    print('Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado.');

    print('Inicializando AndroidAlarmManager...');
    await AndroidAlarmManager.initialize();
    print('AndroidAlarmManager inicializado.');

    print('Inicializando notificaciones...');
    await NotificationsService().initNotification();
    print('Notificaciones inicializadas.');

    print('Programando tarea periódica...');
    await AndroidAlarmManager.periodic(
      const Duration(hours: 1),
      0,
      NotificationsService.checkPendingAppointments,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
    print('Tarea periódica programada.');
  } catch (e) {
    print('Error durante la inicialización: $e');
    rethrow;
  }
}

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final theme = prefs.getString('theme_mode') ?? 'light';
  if (theme == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  } else {
    themeModeNotifier.value = ThemeMode.light;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Antes de dotenv.load()');
    await dotenv.load();
    print('Después de dotenv.load()');
    await initializeApp();
    await loadThemePreference();
    runApp(MyApp(key: myAppKey));
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
  bool _showPermissionsScreen = true;
  bool _loadingPrefs = true;

  @override
  void initState() { 
    super.initState();
    _checkPermissionsScreen();
  }

  Future<void> _checkPermissionsScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('permissions_screen_shown') ?? false;
    setState(() {
      _showPermissionsScreen = !shown;
      _loadingPrefs = false;
    });
  }

  void _onThemeChanged() {}

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return Builder(
          builder: (context) {
            if (_loadingPrefs) {
              return const MaterialApp(
                home: Scaffold(body: Center(child: CircularProgressIndicator())),
              );
            }
            return MaterialApp(
              key: UniqueKey(),
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
              home: _showPermissionsScreen ? const PermissionsScreen() : const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

void forceThemeRebuild() {
  myAppKey.currentState?._onThemeChanged();
}
