import 'package:flutter/material.dart';

class AppColors {
  // Primary agricultural green colors - Prestigious Forest Mode
  static const Color primary = Color(0xFF0F3E12); // Deep Forest Green
  static const Color primaryDark = Color(0xFF072409); // Dark Pine Green
  static const Color primaryLight = Color(0xFFE1EFE2); // Soft Mint Green
  static const Color secondary = Color(0xFF2E7D32); // Emerald Green
  
  // Background & Surface - Unified premium green identity
  static const Color background = Color(0xFFEBF5EC); // Soft minty light green background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF102A12); // Dark green-black text for cards
  static const Color textSecondary = Color(0xFF4A5D4C); // Muted sage green text for cards
  
  // Alert & Diagnostic colors
  static const Color danger = Color(0xFFC62828); // Muted Crimson
  static const Color warning = Color(0xFFE5A93C); // Warm Ochre
  static const Color success = Color(0xFF2E7D32); // Vibrant leaf green
  static const Color info = Color(0xFF0288D1);
  
  // Accent & Card gradients
  static const List<Color> forestGradient = [
    Color(0xFF0F3E12),
    Color(0xFF2E7D32),
  ];
  
  static const List<Color> lightGradient = [
    Color(0xFFE1EFE2),
    Color(0xFFC8E6C9),
  ];
}
