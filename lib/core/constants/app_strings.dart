import 'package:flutter/material.dart';

/// App strings with English and Hebrew translations
/// All UI text should use these methods for i18n support
class AppStrings {
  // Helper method to check if locale is Hebrew
  static bool _isHebrew(Locale locale) => locale.languageCode == 'he';

  // Common strings
  static String appName(Locale locale) => 'AttEnglish';

  static String atti(Locale locale) => 'Atti';

  static String or(Locale locale) => _isHebrew(locale) ? 'או' : 'OR';

  static String loading(Locale locale) => _isHebrew(locale) ? 'טוען...' : 'Loading...';

  // Authentication - Common
  static String email(Locale locale) => _isHebrew(locale) ? 'אימייל' : 'Email Address';

  static String emailHint(Locale locale) =>
      _isHebrew(locale) ? 'example@mail.com' : 'your.email@example.com';

  static String password(Locale locale) => _isHebrew(locale) ? 'סיסמה' : 'Password';

  static String passwordHint(Locale locale) =>
      _isHebrew(locale) ? 'הכנס סיסמה' : 'Enter your password';

  static String confirmPassword(Locale locale) =>
      _isHebrew(locale) ? 'אשר סיסמה' : 'Confirm Password';

  static String confirmPasswordHint(Locale locale) =>
      _isHebrew(locale) ? 'הכנס סיסמה שוב' : 'Re-enter your password';

  static String showPassword(Locale locale) =>
      _isHebrew(locale) ? 'הצג סיסמה' : 'Show password';

  static String hidePassword(Locale locale) =>
      _isHebrew(locale) ? 'הסתר סיסמה' : 'Hide password';

  // Login Screen
  static String login(Locale locale) => _isHebrew(locale) ? 'התחברות' : 'Login';

  static String loginSubtitle(Locale locale) => _isHebrew(locale)
      ? 'התחבר כדי להמשיך במסע הלימודי שלך'
      : 'Sign in to continue your learning journey';

  static String welcomeBack(Locale locale) =>
      _isHebrew(locale) ? 'ברוכים השבים! בואו נלמד ביחד!' : "Welcome back! Let's learn together!";

  static String forgotPassword(Locale locale) =>
      _isHebrew(locale) ? 'שכחת סיסמה?' : 'Forgot your password?';

  static String dontHaveAccount(Locale locale) =>
      _isHebrew(locale) ? 'אין לך חשבון?' : "Don't have an account?";

  static String signUp(Locale locale) => _isHebrew(locale) ? 'הרשמה' : 'Sign Up';

  static String loginSuccess(Locale locale) =>
      _isHebrew(locale) ? 'התחברות בוצעה בהצלחה!' : 'Login successful!';

  static String passwordResetComingSoon(Locale locale) =>
      _isHebrew(locale) ? 'איפוס סיסמה בקרוב! 🔜' : 'Password reset coming soon! 🔜';

  // Sign Up Screen
  static String createAccount(Locale locale) =>
      _isHebrew(locale) ? 'יצירת חשבון' : 'Create Account';

  static String signupSubtitle(Locale locale) => _isHebrew(locale)
      ? 'הרשם כדי להתחיל את מסע הלימוד שלך'
      : 'Sign up to start your learning journey';

  static String letsGetStarted(Locale locale) =>
      _isHebrew(locale) ? 'בואו נתחיל! אני כאן לעזור!' : "Let's get started! I'm here to help!";

  static String alreadyHaveAccount(Locale locale) =>
      _isHebrew(locale) ? 'כבר יש לך חשבון?' : 'Already have an account?';

  static String accountCreatedSuccess(Locale locale) =>
      _isHebrew(locale) ? 'חשבון נוצר בהצלחה! 🎉' : 'Account created successfully! 🎉';

  static String goBack(Locale locale) => _isHebrew(locale) ? 'חזור' : 'Go back';

  // Form Fields
  static String fullName(Locale locale) => _isHebrew(locale) ? 'שם מלא' : 'Full Name';

  static String fullNameHint(Locale locale) =>
      _isHebrew(locale) ? 'ישראל ישראלי' : 'John Smith';

  static String username(Locale locale) => _isHebrew(locale) ? 'שם משתמש' : 'Username';

  static String usernameHint(Locale locale) =>
      _isHebrew(locale) ? 'israeli123' : 'johnsmith123';

  static String schoolName(Locale locale) =>
      _isHebrew(locale) ? 'שם בית הספר' : 'School Name';

  static String schoolNameHint(Locale locale) =>
      _isHebrew(locale) ? 'בית הספר שלך' : 'Your school name';

  static String city(Locale locale) => _isHebrew(locale) ? 'עיר' : 'City';

  static String cityHint(Locale locale) => _isHebrew(locale) ? 'העיר שלך' : 'Your city';

  // Section Headers
  static String personalInformation(Locale locale) =>
      _isHebrew(locale) ? 'מידע אישי' : 'Personal Information';

  static String accountInformation(Locale locale) =>
      _isHebrew(locale) ? 'פרטי חשבון' : 'Account Information';

  static String schoolInformation(Locale locale) =>
      _isHebrew(locale) ? 'מידע על בית הספר' : 'School Information';

  // Validation Messages
  static String pleaseEnterEmail(Locale locale) =>
      _isHebrew(locale) ? 'אנא הכנס אימייל' : 'Please enter your email';

  static String pleaseEnterValidEmail(Locale locale) =>
      _isHebrew(locale) ? 'אנא הכנס אימייל תקין' : 'Please enter a valid email';

  static String pleaseEnterPassword(Locale locale) =>
      _isHebrew(locale) ? 'אנא הכנס סיסמה' : 'Please enter your password';

  static String passwordTooShort(Locale locale) =>
      _isHebrew(locale) ? 'הסיסמה חייבת להכיל לפחות 6 תווים' : 'Password must be at least 6 characters';

  static String pleaseConfirmPassword(Locale locale) =>
      _isHebrew(locale) ? 'אנא אשר את הסיסמה' : 'Please confirm your password';

  static String passwordsDoNotMatch(Locale locale) =>
      _isHebrew(locale) ? 'הסיסמאות אינן תואמות' : 'Passwords do not match';

  static String pleaseEnter(Locale locale, String fieldName) => _isHebrew(locale)
      ? 'אנא הכנס $fieldName'
      : 'Please enter your $fieldName';

  // Home Screen
  static String home(Locale locale) => _isHebrew(locale) ? 'בית' : 'Home';

  static String welcomeToAttEnglish(Locale locale) =>
      _isHebrew(locale) ? 'ברוכים הבאים ל-AttEnglish!' : 'Welcome to AttEnglish!';

  static String loggedInAs(Locale locale) =>
      _isHebrew(locale) ? 'מחובר בתור:' : 'Logged in as:';

  static String signOut(Locale locale) => _isHebrew(locale) ? 'התנתק' : 'Sign Out';

  static String homeUnderConstruction(Locale locale) =>
      _isHebrew(locale) ? 'מסך הבית בבנייה' : 'Home Screen Under Construction';

  static String homeUnderConstructionMessage(Locale locale) => _isHebrew(locale)
      ? 'זהו מסך מציין מיקום. תכונות האפליקציה שלך יתווספו כאן.'
      : 'This is a placeholder home screen. Your app features will be added here.';

  // Error Messages
  static String errorOccurred(Locale locale) =>
      _isHebrew(locale) ? 'אירעה שגיאה' : 'An error occurred';

  static String networkError(Locale locale) =>
      _isHebrew(locale) ? 'שגיאת רשת. אנא בדוק את החיבור שלך.' : 'Network error. Please check your connection.';

  static String tryAgain(Locale locale) => _isHebrew(locale) ? 'נסה שוב' : 'Try Again';

  // Password Requirements
  static String passwordRequirement(Locale locale) =>
      _isHebrew(locale) ? 'לפחות 6 תווים' : 'At least 6 characters';
}
