import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for storing individual lesson completion data with scores
class LessonCompletionModel {
  final String id;
  final String lessonId;
  final String lessonTitle;
  final String studentId;
  final String classId;
  final int score;
  final int maxScore;
  final DateTime completedAt;

  LessonCompletionModel({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.studentId,
    required this.classId,
    required this.score,
    required this.maxScore,
    required this.completedAt,
  });

  /// Calculate score as percentage (0-100)
  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  /// Create from Firestore document
  factory LessonCompletionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonCompletionModel(
      id: doc.id,
      lessonId: data['lessonId'] ?? '',
      lessonTitle: data['lessonTitle'] ?? '',
      studentId: data['studentId'] ?? '',
      classId: data['classId'] ?? '',
      score: data['score'] ?? 0,
      maxScore: data['maxScore'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'studentId': studentId,
      'classId': classId,
      'score': score,
      'maxScore': maxScore,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  @override
  String toString() {
    return 'LessonCompletionModel(id: $id, lessonTitle: $lessonTitle, score: $score/$maxScore)';
  }
}

/// Aggregated progress data for a student
class StudentProgressData {
  final String studentId;
  final String studentName;
  final int lessonsCompleted;
  final double averageScore;
  final List<LessonCompletionModel> completions;

  StudentProgressData({
    required this.studentId,
    required this.studentName,
    required this.lessonsCompleted,
    required this.averageScore,
    required this.completions,
  });

  factory StudentProgressData.fromCompletions(
    String studentId,
    String studentName,
    List<LessonCompletionModel> completions,
  ) {
    final lessonsCompleted = completions.length;
    final averageScore = completions.isEmpty
        ? 0.0
        : completions.map((c) => c.percentage).reduce((a, b) => a + b) /
            completions.length;

    return StudentProgressData(
      studentId: studentId,
      studentName: studentName,
      lessonsCompleted: lessonsCompleted,
      averageScore: averageScore,
      completions: completions,
    );
  }
}
