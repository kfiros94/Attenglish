import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_completion_model.dart';
import '../../auth/models/user_model.dart';
import '../../classroom/models/class_model.dart';

/// Time range filter for progress data
enum TimeRange { day, week, month, all }

/// Service for managing student progress data
class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _completionsCollection = 'lesson_completions';
  static const String _usersCollection = 'users';
  static const String _classesCollection = 'classes';

  /// Save a lesson completion record
  Future<void> saveLessonCompletion({
    required String lessonId,
    required String lessonTitle,
    required String studentId,
    required String classId,
    required int score,
    required int maxScore,
  }) async {
    await _firestore.collection(_completionsCollection).add({
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'studentId': studentId,
      'classId': classId,
      'score': score,
      'maxScore': maxScore,
      'completedAt': Timestamp.now(),
    });
  }

  /// Get all classrooms for a teacher
  Future<List<ClassModel>> getTeacherClassrooms(String teacherId) async {
    final snapshot = await _firestore
        .collection(_classesCollection)
        .where('teacherId', isEqualTo: teacherId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ClassModel.fromJson(data);
    }).toList();
  }

  /// Get students in a classroom
  Future<List<UserModel>> getClassStudents(String classId) async {
    final classDoc = await _firestore
        .collection(_classesCollection)
        .doc(classId)
        .get();

    if (!classDoc.exists) return [];

    final classData = classDoc.data()!;
    final studentIds = List<String>.from(classData['studentIds'] ?? []);

    if (studentIds.isEmpty) return [];

    // Fetch all students in batches (Firestore whereIn limit is 30)
    final students = <UserModel>[];
    for (var i = 0; i < studentIds.length; i += 30) {
      final batchIds = studentIds.sublist(
        i,
        i + 30 > studentIds.length ? studentIds.length : i + 30,
      );

      final snapshot = await _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        students.add(UserModel.fromJson(data));
      }
    }

    return students;
  }

  /// Get class progress data (for macro view charts)
  Future<List<StudentProgressData>> getClassProgress(
    String classId, {
    TimeRange timeRange = TimeRange.all,
  }) async {
    // Get students in the class
    final students = await getClassStudents(classId);
    if (students.isEmpty) return [];

    // Calculate date range
    final now = DateTime.now();
    DateTime? startDate;
    switch (timeRange) {
      case TimeRange.day:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case TimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.all:
        startDate = null;
        break;
    }

    // Get completions for all students in the class
    Query query = _firestore
        .collection(_completionsCollection)
        .where('classId', isEqualTo: classId);

    if (startDate != null) {
      query = query.where(
        'completedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    final snapshot = await query.get();
    final allCompletions = snapshot.docs
        .map((doc) => LessonCompletionModel.fromFirestore(doc))
        .toList();

    // Group completions by student
    final progressList = <StudentProgressData>[];
    for (final student in students) {
      final studentCompletions = allCompletions
          .where((c) => c.studentId == student.id)
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

      progressList.add(StudentProgressData.fromCompletions(
        student.id,
        student.fullName,
        studentCompletions,
      ));
    }

    // Sort by lessons completed (descending)
    progressList.sort((a, b) => b.lessonsCompleted.compareTo(a.lessonsCompleted));

    return progressList;
  }

  /// Get individual student progress (for micro view chart)
  Future<StudentProgressData> getStudentProgress(
    String studentId,
    String classId,
  ) async {
    // Get student info
    final studentDoc = await _firestore
        .collection(_usersCollection)
        .doc(studentId)
        .get();

    if (!studentDoc.exists) {
      return StudentProgressData(
        studentId: studentId,
        studentName: 'Unknown Student',
        lessonsCompleted: 0,
        averageScore: 0,
        completions: [],
      );
    }

    final studentData = studentDoc.data()!;
    studentData['id'] = studentDoc.id;
    final student = UserModel.fromJson(studentData);

    // Get all completions for this student in this class
    final snapshot = await _firestore
        .collection(_completionsCollection)
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .orderBy('completedAt', descending: true)
        .get();

    final completions = snapshot.docs
        .map((doc) => LessonCompletionModel.fromFirestore(doc))
        .toList();

    return StudentProgressData.fromCompletions(
      student.id,
      student.fullName,
      completions,
    );
  }

  /// Get recent activity for a class
  Future<List<LessonCompletionModel>> getRecentClassActivity(
    String classId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection(_completionsCollection)
        .where('classId', isEqualTo: classId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => LessonCompletionModel.fromFirestore(doc))
        .toList();
  }
}
