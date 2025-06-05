import 'package:flutter/material.dart';

/// Central place to define all app colors.
class AppColors {
  // Primary color (app bar, buttons)
  static const Color primary = Color(0xFFB71C1C);
  // Secondary color (highlights)
  static const Color secondary = Color(0xFFFF5722);
  // Background color for scaffold
  static const Color background = Color(0xFF121212);

  // Floating bar colors
  /// Background of the floating bar
  static const Color floatingBarBackground = Color.fromARGB(
    221,
    31,
    30,
    30,
  ); // black87
  /// Text in floating bar (titles)
  static const Color floatingBarText = Color(0xFFFFFFFF);

  /// Icon color in floating bar
  static const Color floatingBarIcon = Color(0xFFFFFFFF);

  /// Placeholder color when no song playing
  static const Color floatingBarPlaceholder = Color(0xFF9E9E9E); // grey

  // Progress bar in floating bar
  /// Background of progress track
  static const Color progressBackground = Color(0xFF424242); // grey.shade800
  /// Buffered portion color
  static const Color progressBuffered = Color(0xFFFFA726); // orange.shade400
}
