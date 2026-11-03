import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  /// Complete [TextTheme] for the app with a clear visual hierarchy.
  ///
  /// * `displayLarge`  – balance amount
  /// * `displayMedium` – large section headers
  /// * `headlineLarge` – screen titles
  /// * `headlineMedium`– section titles
  /// * `titleLarge`    – prominent card titles
  /// * `titleMedium`   – card titles
  /// * `titleSmall`    – sub-titles
  /// * `bodyLarge`     – list items
  /// * `bodyMedium`    – descriptions
  /// * `bodySmall`     – captions
  /// * `labelLarge`    – buttons
  /// * `labelMedium`   – chips / tabs
  /// * `labelSmall`    – metadata / dates
  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      );
}
