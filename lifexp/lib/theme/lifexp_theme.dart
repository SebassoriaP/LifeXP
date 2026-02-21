import 'package:flutter/material.dart';

import 'lifexp_colors.dart';

ThemeData lifexpDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: LifexpColors.xpPrimarySoft,
    secondary: LifexpColors.xpSecondarySoft,
    tertiary: LifexpColors.xpTertiarySoft,
    surface: LifexpColors.surfaceDarkGreen,
    onPrimary: LifexpColors.backgroundDeepBlack,
    onSecondary: LifexpColors.backgroundDeepBlack,
    onTertiary: LifexpColors.backgroundDeepBlack,
    onSurface: LifexpColors.textSilver,
    onError: LifexpColors.textSilver,
    onPrimaryContainer: LifexpColors.textSilver,
    onSecondaryContainer: LifexpColors.textSilver,
    onTertiaryContainer: LifexpColors.textSilver,
    error: Color(0xFFFF6B6B),
  );

  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = base.textTheme.apply(
    bodyColor: LifexpColors.textSilver,
    displayColor: LifexpColors.textSilver,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: LifexpColors.backgroundBlueBlack,
    canvasColor: LifexpColors.backgroundBlueBlack,
    dividerColor: LifexpColors.xpPrimarySoft.withValues(alpha: 0.12),
    textTheme: textTheme.copyWith(
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.25),
      labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LifexpColors.backgroundBlueBlack,
      foregroundColor: LifexpColors.textSilver,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: LifexpColors.textSilver),
      titleTextStyle: TextStyle(
        color: LifexpColors.textSilver,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: LifexpColors.surfaceDarkGreen,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: LifexpColors.xpPrimarySoft.withValues(alpha: 0.16),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LifexpColors.surfaceDarkGreen,
      selectedColor: LifexpColors.xpNeon,
      disabledColor: LifexpColors.surfaceDeepGreen,
      labelStyle: const TextStyle(
        color: LifexpColors.textSilver,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: LifexpColors.backgroundDeepBlack,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: LifexpColors.xpPrimarySoft.withValues(alpha: 0.16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LifexpColors.xpPrimarySoft,
        foregroundColor: LifexpColors.backgroundDeepBlack,
        disabledBackgroundColor: LifexpColors.surfaceDeepGreen,
        disabledForegroundColor: LifexpColors.textSilver.withValues(alpha: 0.7),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LifexpColors.xpPrimarySoft,
        foregroundColor: LifexpColors.backgroundDeepBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LifexpColors.xpTertiarySoft,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LifexpColors.xpPrimarySoft,
      foregroundColor: LifexpColors.backgroundDeepBlack,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LifexpColors.xpPrimarySoft,
      linearTrackColor: LifexpColors.surfaceDeepGreen,
      circularTrackColor: LifexpColors.surfaceDeepGreen,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LifexpColors.surfaceDarkGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: LifexpColors.xpPrimarySoft.withValues(alpha: 0.16),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: LifexpColors.xpPrimarySoft.withValues(alpha: 0.16),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: LifexpColors.xpPrimarySoft, width: 1.2),
      ),
      labelStyle: const TextStyle(color: LifexpColors.textSilver),
      hintStyle: TextStyle(
        color: LifexpColors.textSilver.withValues(alpha: 0.7),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LifexpColors.surfaceDeepGreen,
      contentTextStyle: const TextStyle(color: LifexpColors.textSilver),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
