import 'package:flutter/material.dart';

const xpGreen = Color(0xFF3BE8A4);
const bgDark = Color(0xFF0B0F0D);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bgDark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: xpGreen,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  useMaterial3: true,
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: xpGreen,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);
