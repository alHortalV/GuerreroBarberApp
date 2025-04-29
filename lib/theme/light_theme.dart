import 'package:flutter/material.dart';
import 'package:guerrero_barber_app/theme/theme.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF2B2D42), // Azul muy oscuro/casi negro, elegante
  scaffoldBackgroundColor: const Color(0xFFF9F7F3), // Blanco hueso, más cálido que blanco puro
  
  // Colores del sistema
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF2B2D42), // Azul muy oscuro/casi negro
    secondary: const Color(0xFFD90429), // Rojo vibrante para acentos
    tertiary: const Color(0xFF8D99AE), // Gris azulado para elementos secundarios
    surface: Colors.white,
    background: const Color(0xFFF9F7F3), // Blanco hueso
    error: const Color(0xFFD90429), // Mismo rojo de acento
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: const Color(0xFF2B2D42), // Azul oscuro para texto
    onBackground: const Color(0xFF2B2D42), // Azul oscuro para texto
    onError: Colors.white,
  ),

  // Tema de AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2B2D42),
    elevation: 0, // Sin elevación para un estilo más plano y moderno
    centerTitle: true, // Título centrado para un aspecto más moderno
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
    color: Colors.white,
    elevation: 4,
    shadowColor: const Color(0xFF2B2D42).withOpacity(0.2), // Sombra sutil
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),

  // Tema de Texto
  textTheme: const TextTheme(
    // Títulos
    headlineLarge: TextStyle(
      color: Color(0xFF2B2D42),
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5, // Ligero espaciado negativo para un look moderno
    ),
    headlineMedium: TextStyle(
      color: Color(0xFF2B2D42),
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      color: Color(0xFF2B2D42),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    
    // Títulos de tarjetas y secciones
    titleLarge: TextStyle(
      color: Color(0xFF2B2D42),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      color: Color(0xFF2B2D42),
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: Color(0xFF2B2D42),
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    
    // Texto del cuerpo
    bodyLarge: TextStyle(
      color: Color(0xFF2B2D42),
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: Color(0xFF4A4B57), // Un poco más claro que el principal para texto secundario
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: Color(0xFF8D99AE), // Gris azulado para texto terciario
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
      backgroundColor: const Color(0xFFD90429), // Rojo para botones principales
      elevation: 2,
      shadowColor: const Color(0xFFD90429).withOpacity(0.4),
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
      foregroundColor: const Color(0xFF2B2D42), // Color principal oscuro
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
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF8D99AE).withOpacity(0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF8D99AE).withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2B2D42)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD90429)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    labelStyle: const TextStyle(color: Color(0xFF8D99AE)),
    hintStyle: TextStyle(color: const Color(0xFF8D99AE).withOpacity(0.7)),
    prefixIconColor: const Color(0xFF2B2D42),
    suffixIconColor: const Color(0xFF2B2D42),
  ),

  // Colores específicos para estados de citas
  extensions: [
    CustomThemeExtension(
      appointmentStatusColors: AppointmentStatusColors(
        // Pendiente
        pendingBackground: const Color(0xFFFFF0E0), // Naranja pálido
        pendingText: const Color(0xFFAD6200), // Naranja oscuro
        pendingIcon: const Color(0xFFF29727), // Naranja brillante
        // Confirmada
        confirmedBackground: const Color(0xFFE7F7EE), // Verde pálido
        confirmedText: const Color(0xFF0F623D), // Verde oscuro
        confirmedIcon: const Color(0xFF28A160), // Verde brillante
        // Cancelada
        canceledBackground: const Color(0xFFFBE9E7), // Rojo pálido 
        canceledText: const Color(0xFF9B1B30), // Rojo oscuro
        canceledIcon: const Color(0xFFD90429), // Rojo brillante
      ),
    ),
  ],
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
);