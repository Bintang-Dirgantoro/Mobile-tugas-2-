import 'package:flutter/material.dart';

class AppColors {
  // Modern Friendly Productivity (light)
  static const background = Color(0xFFF4F7F7);
  static const darkTeal = Color(0xFF164D5C);
  static const warmOrange = Color(0xFFF5A623);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF18333B);
  static const textSecondary = Color(0xFF87979B);
  static const cardBackground = Color(0xFFFFFFFF);
  static const paleOrange = Color(0xFFFFF2DC);
  static const lightBlue = Color(0xFFE4F5FB);
  static const lightGreen = Color(0xFFE3F8EC);
  static const lightRed = Color(0xFFFFE7EA);
  static const borderLight = Color(0xFFE0E8EB);

  // Backward-compatible aliases used by existing logic/code
  static const card = cardBackground;
  static const border = borderLight;
  static const textPrimary = textDark;
  static const accent = warmOrange;
  static const primary = darkTeal;
  static const success = Color(0xFF16A34A); // darker so it reads as text on white cards
  static const warning = Color(0xFFB45309); // same reason
  static const danger = Color(0xFFBE0000); // kept from original
  static const iconOrange = warmOrange;
  static const iconGreen = Color(0xFF16A34A);
  static const iconBlue = Color(0xFF0284C7);
  static const iconRed = Color(0xFFE11D48);
  static const iconYellow = Color(0xFFFACC15);
  static const iconPurple = Color(0xFF7C3AED);
}
