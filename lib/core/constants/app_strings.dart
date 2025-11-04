import 'package:flutter/material.dart';

/// App strings with English and Hebrew translations
/// All UI text should use these methods for i18n support
class AppStrings {
  // Helper method to check if locale is Hebrew
  static bool _isHebrew(Locale locale) => locale.languageCode == 'he';

  // Common strings
  static String appName(Locale locale) => 'Attenglish';

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
      _isHebrew(locale) ? 'ברוכים הבאים ל-Attenglish!' : 'Welcome to Attenglish!';

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

  // Classroom Management
  static String myClassrooms(Locale locale) =>
      _isHebrew(locale) ? 'הכיתות שלי' : 'My Classrooms';

  static String manageClassrooms(Locale locale) =>
      _isHebrew(locale) ? 'ניהול כיתות' : 'Manage Classrooms';

  static String createClassroom(Locale locale) =>
      _isHebrew(locale) ? 'צור כיתה' : 'Create Classroom';

  static String createNewClassroom(Locale locale) =>
      _isHebrew(locale) ? 'יצירת כיתה חדשה' : 'Create New Classroom';

  static String classroomName(Locale locale) =>
      _isHebrew(locale) ? 'שם הכיתה' : 'Classroom Name';

  static String classroomNameHint(Locale locale) =>
      _isHebrew(locale) ? 'לדוגמה: כיתה א1' : 'e.g., Class 1A';

  static String grade(Locale locale) => _isHebrew(locale) ? 'כיתה' : 'Grade';

  static String gradeNumber(Locale locale, int grade) =>
      _isHebrew(locale) ? 'כיתה $grade' : 'Grade $grade';

  static String students(Locale locale) => _isHebrew(locale) ? 'תלמידים' : 'Students';

  static String teacher(Locale locale) => _isHebrew(locale) ? 'מורה' : 'Teacher';

  static String noClassrooms(Locale locale) =>
      _isHebrew(locale) ? 'אין כיתות עדיין' : 'No Classrooms Yet';

  static String noClassroomsMessage(Locale locale) => _isHebrew(locale)
      ? 'לחץ על + ליצירת הכיתה הראשונה שלך'
      : 'Click the + button to create your first classroom';

  static String notAssignedToClass(Locale locale) =>
      _isHebrew(locale) ? 'לא משובץ לכיתה עדיין' : 'Not assigned to a class yet';

  static String classroomCreatedSuccess(Locale locale) =>
      _isHebrew(locale) ? 'הכיתה נוצרה בהצלחה!' : 'Classroom created successfully!';

  static String classroomDeletedSuccess(Locale locale) =>
      _isHebrew(locale) ? 'הכיתה נמחקה בהצלחה' : 'Classroom deleted successfully';

  static String deleteClassroom(Locale locale) =>
      _isHebrew(locale) ? 'מחיקת כיתה' : 'Delete Classroom';

  static String deleteClassroomConfirm(Locale locale, String className) =>
      _isHebrew(locale)
          ? 'האם אתה בטוח שברצונך למחוק את הכיתה "$className"?'
          : 'Are you sure you want to delete classroom "$className"?';

  static String delete(Locale locale) => _isHebrew(locale) ? 'מחק' : 'Delete';

  static String cancel(Locale locale) => _isHebrew(locale) ? 'ביטול' : 'Cancel';

  static String create(Locale locale) => _isHebrew(locale) ? 'צור' : 'Create';

  static String errorLoadingClassrooms(Locale locale) =>
      _isHebrew(locale) ? 'שגיאה בטעינת כיתות' : 'Error loading classrooms';

  static String errorCreatingClassroom(Locale locale) =>
      _isHebrew(locale) ? 'שגיאה ביצירת כיתה' : 'Error creating classroom';

  static String errorDeletingClassroom(Locale locale) =>
      _isHebrew(locale) ? 'שגיאה במחיקת כיתה' : 'Error deleting classroom';

  static String school(Locale locale) => _isHebrew(locale) ? 'בית ספר' : 'School';

  static String viewingClassroom(Locale locale, String className) => _isHebrew(locale)
      ? 'תצוגת כיתה $className - בפיתוח'
      : 'Viewing $className - Coming soon';

  // Admin Management
  static String manageTeachers(Locale locale) =>
      _isHebrew(locale) ? 'ניהול מורים' : 'Manage Teachers';

  static String createTeacher(Locale locale) =>
      _isHebrew(locale) ? 'צור מורה' : 'Create Teacher';

  static String createTeacherAccount(Locale locale) =>
      _isHebrew(locale) ? 'יצירת חשבון מורה' : 'Create Teacher Account';

  static String noTeachers(Locale locale) =>
      _isHebrew(locale) ? 'אין מורים עדיין' : 'No Teachers Yet';

  static String noTeachersMessage(Locale locale) => _isHebrew(locale)
      ? 'לחץ על + ליצירת המורה הראשון'
      : 'Click the + button to create your first teacher';

  static String teacherCreatedSuccess(Locale locale) =>
      _isHebrew(locale) ? 'מורה נוצר בהצלחה!' : 'Teacher Created Successfully!';

  static String teacherCreatedLoginAgain(Locale locale) => _isHebrew(locale)
      ? 'המורה נוצר בהצלחה. אנא התחבר שוב כמנהל.'
      : 'The teacher has been created successfully. Please log in again as admin.';

  static String loginAgain(Locale locale) =>
      _isHebrew(locale) ? 'התחבר שוב' : 'Log In Again';

  static String deleteTeacher(Locale locale) =>
      _isHebrew(locale) ? 'מחיקת מורה' : 'Delete Teacher';

  static String deleteTeacherConfirm(Locale locale, String teacherName) =>
      _isHebrew(locale)
          ? 'האם אתה בטוח שברצונך למחוק את המורה "$teacherName"?'
          : 'Are you sure you want to delete teacher "$teacherName"?';

  static String teacherDeletedSuccess(Locale locale) =>
      _isHebrew(locale) ? 'המורה נמחק בהצלחה' : 'Teacher deleted successfully';

  static String errorLoadingTeachers(Locale locale) =>
      _isHebrew(locale) ? 'שגיאה בטעינת מורים' : 'Error loading teachers';

  static String errorCreatingTeacher(Locale locale) =>
      _isHebrew(locale) ? 'שגיאה ביצירת מורה' : 'Error creating teacher';

  static String errorDeletingTeacher(Locale locale) =>
      _isHebrew(locale) ? 'שגיאה במחיקת מורה' : 'Error deleting teacher';

  // Admin Role
  static String admin(Locale locale) => _isHebrew(locale) ? 'מנהל' : 'Admin';

  static String createAdminAccount(Locale locale) =>
      _isHebrew(locale) ? 'יצירת חשבון מנהל' : 'Create Admin Account';

  static String adminSignupMessage(Locale locale) => _isHebrew(locale)
      ? 'בתור מנהל, תוכל ליצור חשבונות מורים ולנהל את המערכת'
      : 'As an admin, you can create teacher accounts and manage the system';
}
