import 'package:flutter/material.dart';

/// ADHD-Friendly Theme for Students (Ages 7-12)
/// Based on research-backed design principles for ADHD children
class ADHDTheme {
  // ADHD-Friendly Color Palette
  static const Color primaryBlue = Color(0xFF4A90E2); // Soft, calming blue
  static const Color secondaryGreen = Color(0xFF7ED321); // Gentle, encouraging green
  static const Color accentOrange = Color(0xFFF5A623); // Warm, energizing orange
  static const Color backgroundLight = Color(0xFFF8F9FA); // Off-white, easy on eyes
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textOnPrimary = Colors.white;

  // Status colors
  static const Color successGreen = Color(0xFF27AE60);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color warningYellow = Color(0xFFF39C12);

  // Progress colors
  static const Color progressFilled = Color(0xFF4A90E2);
  static const Color progressEmpty = Color(0xFFE0E0E0);

  // Badge/Achievement colors
  static const Color badgeGold = Color(0xFFFFD700);
  static const Color badgeSilver = Color(0xFFC0C0C0);
  static const Color badgeBronze = Color(0xFFCD7F32);
  static const Color badgeLocked = Color(0xFFBDBDBD);

  // Spacing (generous for ADHD)
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Border radius (rounded, friendly)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircle = 999.0;

  // Font sizes (large, dyslexia-friendly)
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 18.0;
  static const double fontSizeLarge = 24.0;
  static const double fontSizeXLarge = 32.0;
  static const double fontSizeXXLarge = 40.0;

  // Button dimensions (large touch targets for children)
  static const double buttonHeightSmall = 48.0;
  static const double buttonHeightMedium = 56.0;
  static const double buttonHeightLarge = 64.0;
  static const double touchTargetMin = 48.0; // Minimum touch target size

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Animation durations (quick, not distracting)
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);

  /// Large, friendly button style for primary actions
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: textOnPrimary,
    minimumSize: const Size(double.infinity, buttonHeightLarge),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLarge,
      vertical: spacingMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
    elevation: elevationMedium,
    textStyle: const TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  );

  /// Secondary button style (less prominent)
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryGreen,
    foregroundColor: textOnPrimary,
    minimumSize: const Size(double.infinity, buttonHeightMedium),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLarge,
      vertical: spacingMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: elevationLow,
    textStyle: const TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.w600,
    ),
  );

  /// Card decoration for mission cards
  static BoxDecoration missionCardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Card decoration for progress cards
  static BoxDecoration progressCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        primaryBlue.withOpacity(0.1),
        secondaryGreen.withOpacity(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(
      color: primaryBlue.withOpacity(0.2),
      width: 2,
    ),
  );

  /// Text theme for students (dyslexia-friendly)
  static const TextTheme studentTextTheme = TextTheme(
    // Headlines - large, bold, clear
    displayLarge: TextStyle(
      fontSize: fontSizeXXLarge,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: fontSizeXLarge,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontSize: fontSizeLarge,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      height: 1.3,
    ),

    // Body text - comfortable reading size
    bodyLarge: TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.normal,
      color: textPrimary,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.normal,
      color: textPrimary,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: fontSizeSmall,
      fontWeight: FontWeight.normal,
      color: textSecondary,
      height: 1.4,
    ),

    // Labels - buttons and UI elements
    labelLarge: TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.bold,
      color: textOnPrimary,
      letterSpacing: 0.5,
    ),
  );

  /// Get color for achievement level
  static Color getAchievementColor(String level) {
    switch (level.toLowerCase()) {
      case 'gold':
        return badgeGold;
      case 'silver':
        return badgeSilver;
      case 'bronze':
        return badgeBronze;
      default:
        return badgeLocked;
    }
  }

  /// Get emoji for streak days
  static String getStreakEmoji(int days) {
    if (days >= 30) return '🔥🔥🔥';
    if (days >= 14) return '🔥🔥';
    if (days >= 7) return '🔥';
    if (days >= 3) return '⭐';
    return '🌟';
  }

  /// Get encouraging color based on progress
  static Color getProgressColor(double progress) {
    if (progress >= 0.8) return successGreen;
    if (progress >= 0.5) return primaryBlue;
    if (progress >= 0.3) return accentOrange;
    return secondaryGreen;
  }
}
