/// Model representing a classroom in the system
class ClassModel {
  final String id;
  final String name;
  final String teacherId;
  final int grade;
  final String schoolName;
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.grade,
    required this.schoolName,
    required this.studentIds,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a ClassModel from Firestore JSON
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      teacherId: json['teacherId'] as String,
      grade: json['grade'] as int,
      schoolName: json['schoolName'] as String,
      studentIds: (json['studentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert ClassModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacherId': teacherId,
      'grade': grade,
      'schoolName': schoolName,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of ClassModel with updated fields
  ClassModel copyWith({
    String? id,
    String? name,
    String? teacherId,
    int? grade,
    String? schoolName,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      grade: grade ?? this.grade,
      schoolName: schoolName ?? this.schoolName,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClassModel &&
        other.id == id &&
        other.name == name &&
        other.teacherId == teacherId &&
        other.grade == grade &&
        other.schoolName == schoolName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        teacherId.hashCode ^
        grade.hashCode ^
        schoolName.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'ClassModel(id: $id, name: $name, teacherId: $teacherId, grade: $grade, schoolName: $schoolName, studentCount: ${studentIds.length}, createdAt: $createdAt)';
  }
}
