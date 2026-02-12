import 'package:flutter/material.dart';

class AppColors {
  // 1. Shared Brand Colors (Used in both modes)
  static const Color primary = Color(0xFF6C63FF); // Soft purple
  static const Color accent = Color(0xFFFF6584); // Soft pink
  static const Color textGrey = Color(0xFF9E9E9E);

  // 2. Light Mode Palette
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color cardBgLight = Colors.white;
  static const Color textMainLight = Color(0xFF2D2D2D);

  // 3. Dark Mode Palette (Updated)
  // "Lighter Black" for background (Dark Grey)
  static const Color backgroundDark = Color(0xFF181818);
  // Slightly lighter for cards to create depth
  static const Color cardBgDark = Color(0xFF252525);
  // Pure white text as requested
  static const Color textMainDark = Colors.white;
}
