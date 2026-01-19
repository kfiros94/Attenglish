import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String userName;
  final String fullName;
  final String? email;
  final String role;
  final String schoolName;
  final String city;
  final int? grade;
  final String? classId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Parent details (for students)
  final String? parentFullName;
  final String? parentPhone;
  final String? parentEmail;

  // Gamification fields
  final int xpPoints;              // Total XP earned
  final int currentLevel;          // Current level (1-20+)
  final int currentStreak;         // Current consecutive days
  final int longestStreak;         // Longest streak ever
  final DateTime? lastActivityDate; // Last day student did activity
  final Map<String, int> xpHistory; // Daily XP earned (date -> xp)
  final List<String> completedLessons; // IDs of lessons completed (for "DONE" badge)

  const UserModel({
    required this.id,
    required this.userName,
    required this.fullName,
    this.email,
    required this.role,
    required this.schoolName,
    required this.city,
    this.grade,
    this.classId,
    required this.createdAt,
    this.updatedAt,
    this.parentFullName,
    this.parentPhone,
    this.parentEmail,
    this.xpPoints = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.xpHistory = const {},
    this.completedLessons = const [],
  });

  /// Factory constructor to create a UserModel from Firestore JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      userName: json['userName'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      schoolName: json['schoolName'] as String,
      city: json['city'] as String,
      grade: json['grade'] as int?,
      classId: json['classId'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
      parentFullName: json['parentFullName'] as String?,
      parentPhone: json['parentPhone'] as String?,
      parentEmail: json['parentEmail'] as String?,
      xpPoints: json['xpPoints'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActivityDate: json['lastActivityDate'] != null
          ? _parseDateTime(json['lastActivityDate'])
          : null,
      xpHistory: json['xpHistory'] != null
          ? Map<String, int>.from(json['xpHistory'] as Map)
          : {},
      completedLessons: json['completedLessons'] != null
          ? List<String>.from(json['completedLessons'] as List)
          : [],
    );
  }

  /// Helper method to parse DateTime from either Timestamp or String
  /// Handles both Firestore Timestamp objects and ISO 8601 strings
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    // If it's already a Timestamp object, convert to DateTime
    if (value is Timestamp) {
      return value.toDate();
    }

    // If it's a String, parse it
    if (value is String) {
      return DateTime.parse(value);
    }

    // Fallback for any other type
    return DateTime.now();
  }

  /// Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'role': role,
      'schoolName': schoolName,
      'city': city,
      'grade': grade,
      'classId': classId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'parentFullName': parentFullName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      'xpPoints': xpPoints,
      'currentLevel': currentLevel,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'xpHistory': xpHistory,
      'completedLessons': completedLessons,
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? userName,
    String? fullName,
    String? email,
    String? role,
    String? schoolName,
    String? city,
    int? grade,
    String? classId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentFullName,
    String? parentPhone,
    String? parentEmail,
    int? xpPoints,
    int? currentLevel,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    Map<String, int>? xpHistory,
    List<String>? completedLessons,
  }) {
    return UserModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      schoolName: schoolName ?? this.schoolName,
      city: city ?? this.city,
      grade: grade ?? this.grade,
      classId: classId ?? this.classId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentFullName: parentFullName ?? this.parentFullName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      xpPoints: xpPoints ?? this.xpPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      xpHistory: xpHistory ?? this.xpHistory,
      completedLessons: completedLessons ?? this.completedLessons,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.userName == userName &&
        other.fullName == fullName &&
        other.email == email &&
        other.role == role &&
        other.schoolName == schoolName &&
        other.city == city &&
        other.grade == grade &&
        other.classId == classId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.xpPoints == xpPoints &&
        other.currentLevel == currentLevel &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.lastActivityDate == lastActivityDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userName.hashCode ^
        fullName.hashCode ^
        email.hashCode ^
        role.hashCode ^
        schoolName.hashCode ^
        city.hashCode ^
        grade.hashCode ^
        classId.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        xpPoints.hashCode ^
        currentLevel.hashCode ^
        currentStreak.hashCode ^
        longestStreak.hashCode ^
        lastActivityDate.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, userName: $userName, fullName: $fullName, email: $email, role: $role, schoolName: $schoolName, city: $city, grade: $grade, classId: $classId, createdAt: $createdAt, updatedAt: $updatedAt, xpPoints: $xpPoints, currentLevel: $currentLevel, currentStreak: $currentStreak, longestStreak: $longestStreak, lastActivityDate: $lastActivityDate)';
  }
}
