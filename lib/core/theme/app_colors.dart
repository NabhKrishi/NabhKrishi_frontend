import 'package:flutter/material.dart';

/// Centralized color tokens for NabhKrishi.
/// Keeping these in one place means every screen (splash, dashboard,
/// weather, advisory, etc.) stays visually consistent.
class AppColors {
  AppColors._();

  // Brand — "Nabh" (sky) meets "Krishi" (farming): sky blue fading into earth green.
  static const Color skyBlueDark = Color(0xFF0D47A1);
  static const Color skyBlueLight = Color(0xFF4FC3F7);
  static const Color earthGreenLight = Color(0xFF66BB6A);
  static const Color earthGreenDark = Color(0xFF1B5E20);

  static const Color amberAccent = Color(0xFFFFB300);

  static const Color ivory = Color(0xFFFDFBF6);
  static const Color charcoal = Color(0xFF212121);

  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  /// The signature splash gradient: sky at the top, earth at the bottom.
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      skyBlueDark,
      skyBlueLight,
      earthGreenLight,
      earthGreenDark,
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );
}
