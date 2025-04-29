import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/theme/theme.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  
  // Colores base del tema
  primaryColor: const Color(0xFF181818), // Negro elegante
  scaffoldBackgroundColor: const Color(0xFF121212), // Negro profundo para el fondo
  
  // Esquema de colores
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF181818), // Negro elegante
    secondary: const Color(0xFFD90429), // Rojo vibrante consistente con el tema claro
    tertiary: const Color(0xFF8D99AE), // Gris azulado
    surface: const Color(0xFF1E1E1E), // Gris muy oscuro para tarjetas
    background: const Color(0xFF121212), // Negro profundo
    error: const Color(0xFFD90429), // Rojo consistente
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
    brightness: Brightness.dark,
  ),

  // Tema de AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF181818), // Negro elegante
    elevation: 0, // Sin elevación para aspecto moderno
    centerTitle: true, // Título centrado
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5, // Ligero espaciado para elegancia
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),

  // Tema de Card
  cardTheme: CardTheme(
    color: const Color(0xFF242424), // Gris oscuro para tarjetas
    elevation: 8, // Un poco más de elevación para que destaque en fondo oscuro
    shadowColor: Colors.black.withOpacity(0.5), // Sombra más pronunciada en modo oscuro
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),

  // Tema de Texto
  textTheme: const TextTheme(
    // Títulos
    headlineLarge: TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5, // Ligero espaciado negativo para un look moderno
    ),
    headlineMedium: TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    
    // Títulos de tarjetas y secciones
    titleLarge: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    
    // Texto del cuerpo
    bodyLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFFDFDFDF), // Blanco ligeramente grisáceo
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: Color(0xFFAEAEB2), // Gris claro para texto terciario
      fontSize: 12,
    ),
    
    // Etiquetas y botones
    labelLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5, // Ligero espaciado para elegancia
    ),
  ),

  // Tema de Botones Elevados
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFFD90429), // Rojo consistente con tema claro
      elevation: 4,
      shadowColor: const Color(0xFFD90429).withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),

  // Tema de Botones de Texto
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFEF233C), // Un tono más claro del rojo para visibilidad
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
    fillColor: const Color(0xFF1E1E1E), // Un tono más claro que el fondo
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD90429)), // Rojo cuando está enfocado
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD90429)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    labelStyle: const TextStyle(color: Color(0xFFAEAEB2)),
    hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
    prefixIconColor: const Color(0xFFAEAEB2),
    suffixIconColor: const Color(0xFFAEAEB2),
  ),

  // Tema de Divider
  dividerTheme: DividerThemeData(
    color: Colors.grey[800],
    thickness: 1,
    space: 16,
  ),

  // Tema de BottomNavigationBar
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFF181818),
    selectedItemColor: const Color(0xFFD90429), // Rojo para selección
    unselectedItemColor: Colors.grey[400],
    elevation: 8,
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
        return const Color(0xFFD90429).withOpacity(0.5); // Rojo semi-transparente para la pista
      }
      return Colors.grey[800];
    }),
  ),

  // Colores específicos para estados de citas
  extensions: [
    CustomThemeExtension(
      appointmentStatusColors: AppointmentStatusColors(
        // Pendiente
        pendingBackground: const Color(0xFF3D2E16), // Naranja muy oscuro
        pendingText: const Color(0xFFFCB762), // Naranja claro para texto
        pendingIcon: const Color(0xFFF29727), // Naranja brillante
        // Confirmada
        confirmedBackground: const Color(0xFF0F362A), // Verde oscuro
        confirmedText: const Color(0xFF4CD080), // Verde claro para texto
        confirmedIcon: const Color(0xFF28A160), // Verde brillante
        // Cancelada
        canceledBackground: const Color(0xFF331016), // Rojo oscuro
        canceledText: const Color(0xFFFF8A9A), // Rojo claro para texto
        canceledIcon: const Color(0xFFD90429), // Rojo brillante
      ),
    ),
  ],

  // Otros ajustes generales
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);