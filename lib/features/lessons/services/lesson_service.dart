import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  // ============================================================================
  // FILE UPLOAD METHODS
  // ============================================================================

  /// Upload audio file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadAudio(
    String lessonId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      // Validate file type
      if (!isValidAudioFile(fileName)) {
        throw Exception(
          'Invalid audio file type. Allowed: .mp3, .wav, .m4a',
        );
      }

      // Validate file size (max 10MB for audio)
      if (!isFileSizeValid(fileBytes.length, 10)) {
        throw Exception('Audio file too large. Maximum size: 10MB');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = fileName.replaceAll(' ', '_');
      final storagePath = 'lessons/$lessonId/audio/audio_${timestamp}_$sanitizedFileName';

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: _getAudioContentType(fileName),
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }

  /// Upload image file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadImage(
    String lessonId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      print('[LessonService] Starting uploadImage: $fileName');

      // Validate file type
      if (!isValidImageFile(fileName)) {
        throw Exception(
          'Invalid image file type. Allowed: .jpg, .jpeg, .png, .gif',
        );
      }
      print('[LessonService] File type validation passed');

      // Validate file size (max 5MB for images)
      if (!isFileSizeValid(fileBytes.length, 5)) {
        throw Exception('Image file too large. Maximum size: 5MB');
      }
      print('[LessonService] File size validation passed: ${fileBytes.length} bytes');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = fileName.replaceAll(' ', '_');
      final storagePath = 'lessons/$lessonId/images/image_${timestamp}_$sanitizedFileName';
      print('[LessonService] Storage path: $storagePath');

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      print('[LessonService] Starting Firebase upload...');

      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: _getImageContentType(fileName),
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      print('[LessonService] Upload completed');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('[LessonService] Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('[LessonService] Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Parse the URL to get the storage reference
      final ref = _storage.refFromURL(fileUrl);

      // Delete the file
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // ============================================================================
  // FILE VALIDATION HELPER METHODS
  // ============================================================================

  /// Check if file is a valid audio file
  bool isValidAudioFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['mp3', 'wav', 'm4a'].contains(extension);
  }

  /// Check if file is a valid image file
  bool isValidImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }

  /// Check if file size is within limit
  /// maxMB: maximum size in megabytes
  bool isFileSizeValid(int bytes, int maxMB) {
    final maxBytes = maxMB * 1024 * 1024;
    return bytes <= maxBytes;
  }

  /// Get content type for audio file
  String _getAudioContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      default:
        return 'audio/mpeg';
    }
  }

  /// Get content type for image file
  String _getImageContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
