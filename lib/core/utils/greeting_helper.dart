import 'package:flutter/material.dart';

/// Helper class for time-based greetings
class GreetingHelper {
  /// Get time-based greeting text based on locale
  static String getGreeting(Locale locale) {
    final hour = DateTime.now().hour;
    final isHebrew = locale.languageCode == 'he';

    if (hour >= 5 && hour < 12) {
      // Morning: 5:00 AM - 11:59 AM
      return isHebrew ? 'בוקר טוב' : 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: 12:00 PM - 4:59 PM
      return isHebrew ? 'צהריים טובים' : 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      // Evening: 5:00 PM - 8:59 PM
      return isHebrew ? 'ערב טוב' : 'Good evening';
    } else {
      // Night: 9:00 PM - 4:59 AM
      return isHebrew ? 'לילה טוב' : 'Good night';
    }
  }

  /// Get emoji icon based on time of day
  static String getGreetingIcon() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return '☀️'; // Morning sun
    } else if (hour >= 12 && hour < 17) {
      return '🌤️'; // Afternoon sun with clouds
    } else if (hour >= 17 && hour < 21) {
      return '🌆'; // Evening cityscape
    } else {
      return '🌙'; // Night moon
    }
  }

  /// Get full greeting with name
  static String getFullGreeting(Locale locale, String name) {
    final greeting = getGreeting(locale);
    final isHebrew = locale.languageCode == 'he';

    if (isHebrew) {
      return '$greeting, $name!';
    } else {
      return '$greeting, $name!';
    }
  }

  /// Get mascot message based on time of day
  static String getMascotMessage(Locale locale, String name) {
    final hour = DateTime.now().hour;
    final isHebrew = locale.languageCode == 'he';

    if (hour >= 5 && hour < 12) {
      // Morning
      return isHebrew
          ? 'מוכנים ללמוד היום, $name?'
          : 'Ready to learn today, $name?';
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      return isHebrew
          ? 'בואו נמשיך ללמוד, $name!'
          : "Let's keep learning, $name!";
    } else if (hour >= 17 && hour < 21) {
      // Evening
      return isHebrew
          ? 'זמן טוב ללמוד, $name!'
          : 'Great time to learn, $name!';
    } else {
      // Night
      return isHebrew
          ? 'למידה לפני השינה, $name?'
          : 'Learning before bed, $name?';
    }
  }
}
