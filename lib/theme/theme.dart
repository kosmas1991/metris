import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: false,
  scaffoldBackgroundColor: Colors.black,
  fontFamily: 'PressStart2P',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Colors.green,
      fontFamily: 'PressStart2P',
    ),
    bodyMedium: TextStyle(
      color: Colors.green,
      fontFamily: 'PressStart2P',
    ),
    titleLarge: TextStyle(
      color: Colors.green,
      fontFamily: 'PressStart2P',
      fontWeight: FontWeight.bold,
    ),
  ),
  colorScheme: ColorScheme.dark(
    primary: Colors.green,
    secondary: Colors.green.shade700,
    surface: Colors.black,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.green,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.green,
      side: const BorderSide(color: Colors.green, width: 3),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      textStyle: const TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 1,
      ),
      shadowColor: Colors.green.withAlpha(50),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(Colors.green),
      overlayColor: WidgetStateProperty.all(Colors.green.withAlpha(20)),
    ),
  ),
);
