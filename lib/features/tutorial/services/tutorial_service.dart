import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage tutorial state and first-time user experience
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  static TutorialService get instance => _instance;
  TutorialService._internal();

  static const String _studentTutorialKey = 'student_tutorial_completed';
  static const String _teacherTutorialKey = 'teacher_tutorial_completed';
  static const String _adminTutorialKey = 'admin_tutorial_completed';

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if student tutorial has been completed
  Future<bool> hasCompletedStudentTutorial() async {
    await initialize();
    return _prefs?.getBool(_studentTutorialKey) ?? false;
  }

  /// Check if teacher tutorial has been completed
  Future<bool> hasCompletedTeacherTutorial() async {
    await initialize();
    return _prefs?.getBool(_teacherTutorialKey) ?? false;
  }

  /// Check if admin tutorial has been completed
  Future<bool> hasCompletedAdminTutorial() async {
    await initialize();
    return _prefs?.getBool(_adminTutorialKey) ?? false;
  }

  /// Mark student tutorial as completed
  Future<void> completeStudentTutorial() async {
    await initialize();
    await _prefs?.setBool(_studentTutorialKey, true);
  }

  /// Mark teacher tutorial as completed
  Future<void> completeTeacherTutorial() async {
    await initialize();
    await _prefs?.setBool(_teacherTutorialKey, true);
  }

  /// Mark admin tutorial as completed
  Future<void> completeAdminTutorial() async {
    await initialize();
    await _prefs?.setBool(_adminTutorialKey, true);
  }

  /// Reset tutorial state (for replay)
  Future<void> resetStudentTutorial() async {
    await initialize();
    await _prefs?.setBool(_studentTutorialKey, false);
  }

  /// Reset teacher tutorial state (for replay)
  Future<void> resetTeacherTutorial() async {
    await initialize();
    await _prefs?.setBool(_teacherTutorialKey, false);
  }

  /// Reset admin tutorial state (for replay)
  Future<void> resetAdminTutorial() async {
    await initialize();
    await _prefs?.setBool(_adminTutorialKey, false);
  }

  /// Check tutorial completion based on user role
  Future<bool> hasCompletedTutorial(String role) async {
    switch (role.toLowerCase()) {
      case 'student':
        return hasCompletedStudentTutorial();
      case 'teacher':
        return hasCompletedTeacherTutorial();
      case 'admin':
        return hasCompletedAdminTutorial();
      default:
        return true;
    }
  }

  /// Mark tutorial as completed based on user role
  Future<void> completeTutorial(String role) async {
    switch (role.toLowerCase()) {
      case 'student':
        await completeStudentTutorial();
        break;
      case 'teacher':
        await completeTeacherTutorial();
        break;
      case 'admin':
        await completeAdminTutorial();
        break;
    }
  }

  /// Reset tutorial based on user role
  Future<void> resetTutorial(String role) async {
    switch (role.toLowerCase()) {
      case 'student':
        await resetStudentTutorial();
        break;
      case 'teacher':
        await resetTeacherTutorial();
        break;
      case 'admin':
        await resetAdminTutorial();
        break;
    }
  }
}
