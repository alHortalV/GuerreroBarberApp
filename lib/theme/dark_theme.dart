import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/theme/theme.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,

  // Colores base del tema
  primaryColor: const Color(0xFF2C2C2C),
  scaffoldBackgroundColor: const Color(0xFF1A1A1A),

  // Esquema de colores
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF2C2C2C),
    secondary: const Color(0xFFD90429),
    tertiary: const Color(0xFF8D99AE),
    surface: const Color(0xFF262626),
    background: const Color(0xFF1A1A1A),
    error: const Color(0xFFD90429),
    onPrimary: const Color(0xFFF5F5F5),
    onSecondary: const Color(0xFFF5F5F5),
    onSurface: const Color(0xFFF5F5F5),
    onBackground: const Color(0xFFF5F5F5),
    onError: const Color(0xFFF5F5F5),
    brightness: Brightness.dark,
  ),

  // Tema de AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2C2C2C),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    iconTheme: IconThemeData(color: Color(0xFFF5F5F5)),
  ),

  // Tema de Card
  cardTheme: CardTheme(
    color: const Color.fromARGB(
        95, 90, 90, 90), // Fondo transparente para permitir gradiente
    elevation: 0, // Sin elevación para el efecto personalizado
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  // Tema de Texto
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: Color(0xFFF5F5F5),
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: Color(0xFFBDBDBD),
      fontSize: 12,
    ),
  ),

  // Tema de Botones Elevados
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Color(0xFFF5F5F5),
      backgroundColor: Color(0xFFD90429),
      elevation: 4,
      shadowColor: Color(0xFFD90429).withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),

  // Tema de Botones de Texto
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor:
          const Color(0xFFF5F5F5), // Blanco apagado para modo oscuro
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),

  // Tema de Campos de Texto
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF424242)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF424242)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD90429)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD90429)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
  ),

  // Tema de BottomNavigationBar
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF2C2C2C),
    selectedItemColor: Color(0xFFD90429),
    unselectedItemColor: Color(0xFF9E9E9E),
    elevation: 8,
  ),

  // Tema de Divider
  dividerTheme: const DividerThemeData(
    color: Color(0xFF424242),
    thickness: 1,
    space: 16,
  ),

  // Tema de Switch
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFFD90429); // Rojo cuando está activado
      }
      return Colors.grey[400];
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFFD90429)
            .withOpacity(0.5); // Rojo semi-transparente para la pista
      }
      return Colors.grey[800];
    }),
  ),

  // Colores específicos para estados de citas
  extensions: [
    CustomThemeExtension(
      appointmentStatusColors: AppointmentStatusColors(
        // Pendiente
        pendingBackground: Colors.orange.withAlpha(60),
        pendingText: Colors.orange[300]!,
        pendingIcon: Colors.orange[400]!,
        // Confirmada
        confirmedBackground: Color.fromARGB(255, 36, 121, 73).withAlpha(60),
        confirmedText: Colors.green[300]!,
        confirmedIcon: Colors.green[400]!,
        // Cancelada
        canceledBackground: Colors.red,
        canceledText: Colors.red[300]!,
        canceledIcon: Colors.red[400]!,
      ),
    ),
  ],

  // Tema de Iconos
  iconTheme: IconThemeData(
    color: Colors.white, // Blanco puro para iconos en modo oscuro
    size: 24,
  ),

  // Otros ajustes generales
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
