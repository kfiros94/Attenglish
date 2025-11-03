class UserModel {
  final String id;
  final String userName;
  final String fullName;
  final String? email;
  final String role;
  final String schoolName;
  final String city;
  final int? grade;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.userName,
    required this.fullName,
    this.email,
    required this.role,
    required this.schoolName,
    required this.city,
    this.grade,
    required this.createdAt,
    this.updatedAt,
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
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
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, userName: $userName, fullName: $fullName, email: $email, role: $role, schoolName: $schoolName, city: $city, grade: $grade, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
