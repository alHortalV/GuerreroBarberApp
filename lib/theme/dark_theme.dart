import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  // Usamos tonos más oscuros de los mismos colores
  primaryColor: Colors.blue[900],
  scaffoldBackgroundColor: Colors.grey[900],
  hintColor: Colors.red[700],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.red[900], // AppBar en tono rojizo oscuro
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    labelLarge: TextStyle(color: Colors.white, fontSize: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.red[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
);
