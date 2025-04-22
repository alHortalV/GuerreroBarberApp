import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:guerrero_barber_app/services/notifications_service.dart';
import 'package:guerrero_barber_app/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guerrero_barber_app/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Solicita permiso para notificaciones en Android 13+
  if (Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
    await Permission.notification.request();
  }

  await NotificationsService().initNotification();
  runApp(const MyApp());
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
