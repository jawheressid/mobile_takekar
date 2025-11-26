import 'package:flutter/material.dart';

class AppColors {
  static const Color sunrise = Color(0xFFFFB300);
  static const Color sunriseDeep = Color(0xFFFF9800);
  static const Color surface = Color(0xFFFFF7E8);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF20242C);
  static const Color textSecondary = Color(0xFF5A6470);
  static const Color accentPink = Color(0xFFFF5277);
}

const LinearGradient sunriseGradient = LinearGradient(
  colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
