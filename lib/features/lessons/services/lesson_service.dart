import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

/// Service for managing lessons in Firestore
/// Implements singleton pattern
class LessonService {
  // Private constructor for singleton
  LessonService._();

  // Singleton instance
  static final LessonService instance = LessonService._();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static const String _lessonsCollection = 'lessons';

  /// Create a new lesson
  /// Returns the lesson ID
  Future<String> createLesson(LessonModel lesson) async {
    try {
      final docRef = await _firestore
          .collection(_lessonsCollection)
          .add(lesson.toJson());

      // Update the lesson with its generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create lesson: $e');
    }
  }

  /// Update an existing lesson
  Future<void> updateLesson(String lessonId, LessonModel lesson) async {
    try {
      final lessonWithTimestamp = lesson.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_lessonsCollection)
          .doc(lessonId)
          .update(lessonWithTimestamp.toJson());
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  /// Delete a lesson
  Future<void> deleteLesson(String lessonId) async {
    try {
      await _firestore.collection(_lessonsCollection).doc(lessonId).delete();
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }

  /// Get all lessons for a teacher
  Future<List<LessonModel>> getTeacherLessons(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_lessonsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final lessons = querySnapshot.docs
          .map((doc) => LessonModel.fromJson(doc.data()))
          .toList();

      // Sort by created date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return lessons;
    } catch (e) {
      throw Exception('Failed to get teacher lessons: $e');
    }
  }

  /// Get all lessons for a classroom
  Future<List<LessonModel>> getClassLessons(String classId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_lessonsCollection)
          .where('classId', isEqualTo: classId)
          .where('status', isEqualTo: 'published')
          .get();

      final lessons = querySnapshot.docs
          .map((doc) => LessonModel.fromJson(doc.data()))
          .toList();

      // Sort by created date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return lessons;
    } catch (e) {
      throw Exception('Failed to get class lessons: $e');
    }
  }

  /// Get a single lesson by ID
  Future<LessonModel?> getLesson(String lessonId) async {
    try {
      final doc =
          await _firestore.collection(_lessonsCollection).doc(lessonId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      return LessonModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get lesson: $e');
    }
  }

  /// Stream of teacher's lessons (real-time updates)
  Stream<List<LessonModel>> teacherLessonsStream(String teacherId) {
    return _firestore
        .collection(_lessonsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
      final lessons =
          snapshot.docs.map((doc) => LessonModel.fromJson(doc.data())).toList();

      // Sort by created date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return lessons;
    });
  }

  /// Stream of classroom lessons (real-time updates for students)
  /// Only returns published lessons
  Stream<List<LessonModel>> classLessonsStream(String classId) {
    return _firestore
        .collection(_lessonsCollection)
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
      final lessons =
          snapshot.docs.map((doc) => LessonModel.fromJson(doc.data())).toList();

      // Sort by created date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return lessons;
    });
  }

  /// Get filtered lessons
  Future<List<LessonModel>> getFilteredLessons({
    required String teacherId,
    String? classId,
    String? status,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore
          .collection(_lessonsCollection)
          .where('teacherId', isEqualTo: teacherId);

      if (classId != null && classId.isNotEmpty) {
        query = query.where('classId', isEqualTo: classId);
      }

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();
      var lessons = querySnapshot.docs
          .map((doc) => LessonModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply search filter on title
      if (searchQuery != null && searchQuery.isNotEmpty) {
        lessons = lessons
            .where((lesson) => lesson.title
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();
      }

      // Sort by created date (newest first)
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return lessons;
    } catch (e) {
      throw Exception('Failed to get filtered lessons: $e');
    }
  }
}
