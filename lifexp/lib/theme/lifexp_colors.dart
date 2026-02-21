import 'package:flutter/material.dart';

class LifexpColors {
  static const xpNeon = Color(0xFF39FF14);
  static const xpGreenMid = Color(0xFF32E000);
  static const xpLimeGlow = Color(0xFFA6FF3B);
  static const glowStar = Color(0xFFCFFF2E);
  static const xpPrimarySoft = Color(0xFF6BCF4C);
  static const xpSecondarySoft = Color(0xFF5FB748);
  static const xpTertiarySoft = Color(0xFF9AD95A);

  static const backgroundDeepBlack = Color(0xFF050505);
  static const backgroundBlueBlack = Color(0xFF0B0F1A);
  static const surfaceDarkGreen = Color(0xFF0A0F0A);
  static const surfaceDeepGreen = Color(0xFF0F2F0A);

  static const textSilver = Color(0xFFE5E7EB);
}

class LifexpGradients {
  static const xpOfficial = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      LifexpColors.xpNeon,
      LifexpColors.xpGreenMid,
      LifexpColors.xpLimeGlow,
    ],
    stops: [0.0, 0.4, 1.0],
  );

  static const xpOfficialSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      LifexpColors.xpPrimarySoft,
      LifexpColors.xpSecondarySoft,
      LifexpColors.xpTertiarySoft,
    ],
    stops: [0.0, 0.4, 1.0],
  );

  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      LifexpColors.backgroundDeepBlack,
      LifexpColors.backgroundBlueBlack,
    ],
  );
}

class LifexpShadows {
  static List<BoxShadow> subtlePrimaryGlow = [
    BoxShadow(
      color: LifexpColors.xpPrimarySoft.withValues(alpha: 0.16),
      blurRadius: 12,
      spreadRadius: 0.4,
    ),
  ];
}
