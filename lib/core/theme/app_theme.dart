import 'package:flutter/material.dart';

/// ADHD-Friendly Color Palette
/// Calm, low-stimulus colors designed to reduce cognitive load
class AppColors {
  // Primary Colors - Calm and Soothing
  static const Color primary = Color(0xFF4A90E2); // Soft blue
  static const Color primaryLight = Color(0xFF7BB3F0);
  static const Color primaryDark = Color(0xFF2E5A8E);

  // Secondary Colors - Gentle and Encouraging
  static const Color secondary = Color(0xFF7ED321); // Gentle green
  static const Color secondaryLight = Color(0xFFA4E157);
  static const Color secondaryDark = Color(0xFF5FA319);

  // Accent Colors
  static const Color accent = Color(0xFFF5A623); // Warm orange
  static const Color accentLight = Color(0xFFF8BD59);
  static const Color accentDark = Color(0xFFD18A0F);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA); // Off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF0F2F5);

  // Text Colors - High Contrast for Readability
  static const Color textPrimary = Color(0xFF2C3E50); // Dark blue-gray
  static const Color textSecondary = Color(0xFF5A6C7D); // Medium gray
  static const Color textTertiary = Color(0xFF8A9BAC); // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Feedback Colors
  static const Color success = Color(0xFF52C41A);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);

  // Borders and Dividers
  static const Color border = Color(0xFFE0E6ED);
  static const Color divider = Color(0xFFEEF2F7);
}

/// ADHD-Friendly Theme Configuration
class AppTheme {
  // Spacing Constants - Generous spacing reduces visual clutter
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Font Sizes - Large and readable
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 32.0;

  /// Get the light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
      ),

      // Text Theme - Dyslexia-friendly, high contrast
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.3,
          letterSpacing: 0.25,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          height: 1.3,
          letterSpacing: 0.2,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
          letterSpacing: 0.15,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          height: 1.5,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.4,
          letterSpacing: 0.1,
        ),
      ),

      // Input Decoration Theme - Clear, accessible inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2.5),
        ),
        labelStyle: const TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: fontSizeMedium,
          color: AppColors.textTertiary,
        ),
        errorStyle: const TextStyle(
          fontSize: fontSizeSmall,
          color: AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Elevated Button Theme - Clear, accessible buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.all(spacingSmall),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontSize: fontSizeMedium,
          color: AppColors.textOnPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: spacingMedium,
      ),
    );
  }
}
