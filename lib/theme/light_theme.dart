import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.red, // color de fondo para AppBar en modo claro
    titleTextStyle: const TextStyle(
      color: Color.fromARGB(255, 37, 83, 105),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: const IconThemeData(color: Color.fromARGB(255, 37, 83, 105)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color.fromARGB(255, 37, 83, 105)),
    labelLarge: TextStyle(color: Colors.white, fontSize: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.red,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.redAccent),
);
