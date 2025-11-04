import 'package:cloud_firestore/cloud_firestore.dart';

/// Lesson model for storing lesson data
class LessonModel {
  final String id;
  final String title;
  final String? description;
  final String classId;
  final String teacherId;
  final int grade;
  final int difficulty; // 1-5 (Easy to Expert)
  final String? topic;
  final String textContent;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'draft' or 'published'

  const LessonModel({
    required this.id,
    required this.title,
    this.description,
    required this.classId,
    required this.teacherId,
    required this.grade,
    required this.difficulty,
    this.topic,
    required this.textContent,
    required this.createdAt,
    this.updatedAt,
    required this.status,
  });

  /// Create LessonModel from Firestore JSON
  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      classId: json['classId'] as String,
      teacherId: json['teacherId'] as String,
      grade: json['grade'] as int,
      difficulty: json['difficulty'] as int,
      topic: json['topic'] as String?,
      textContent: json['textContent'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      status: json['status'] as String,
    );
  }

  /// Convert LessonModel to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'classId': classId,
      'teacherId': teacherId,
      'grade': grade,
      'difficulty': difficulty,
      'topic': topic,
      'textContent': textContent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
    };
  }

  /// Create a copy with modified fields
  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? classId,
    String? teacherId,
    int? grade,
    int? difficulty,
    String? topic,
    String? textContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      grade: grade ?? this.grade,
      difficulty: difficulty ?? this.difficulty,
      topic: topic ?? this.topic,
      textContent: textContent ?? this.textContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  /// Get difficulty label
  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Very Hard';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  /// Get status label with emoji
  String get statusLabel {
    return status == 'published' ? '✓ Published' : '📝 Draft';
  }
}
