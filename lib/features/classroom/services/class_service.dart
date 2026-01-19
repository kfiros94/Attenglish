import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';
import '../../auth/models/user_model.dart';

/// Service for managing classroom operations
/// Implements singleton pattern to ensure single instance across the app
class ClassService {
  // Private constructor for singleton
  ClassService._();

  // Singleton instance
  static final ClassService instance = ClassService._();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  static const String _classesCollection = 'classes';
  static const String _usersCollection = 'users';

  /// Create a new classroom
  Future<void> createClass(ClassModel classData) async {
    try {
      final classWithTimestamp = classData.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_classesCollection)
          .doc(classData.id)
          .set(classWithTimestamp.toJson());
    } catch (e) {
      throw Exception('Failed to create classroom: $e');
    }
  }

  /// Add a student to a classroom
  /// Also updates the student's classId in their user document
  Future<void> addStudentToClass(String classId, String studentId) async {
    try {
      print('🔵 Adding student $studentId to class $classId');

      // Get class document
      final classDoc =
          await _firestore.collection(_classesCollection).doc(classId).get();

      if (!classDoc.exists) {
        print('❌ Classroom not found: $classId');
        throw Exception('Classroom not found');
      }

      final classData = ClassModel.fromJson(classDoc.data()!);
      print('✅ Class found: ${classData.name}, current students: ${classData.studentIds.length}');

      // Check if student is already in the class
      if (classData.studentIds.contains(studentId)) {
        print('⚠️ Student already in class');
        return; // Already added
      }

      // Update class with new student
      final updatedStudentIds = [...classData.studentIds, studentId];
      print('🔄 Updating class with ${updatedStudentIds.length} students');

      await _firestore.collection(_classesCollection).doc(classId).update({
        'studentIds': updatedStudentIds,
        'updatedAt': Timestamp.now(),
      });
      print('✅ Class updated successfully');

      // Update student's user document with classId
      print('🔄 Updating student document with classId: $classId');
      await _firestore.collection(_usersCollection).doc(studentId).update({
        'classId': classId,
        'updatedAt': Timestamp.now(),
      });
      print('✅ Student added successfully to class $classId');
    } catch (e) {
      print('❌ Error adding student to classroom: $e');
      throw Exception('Failed to add student to classroom: $e');
    }
  }

  /// Remove a student from a classroom
  /// Also removes the classId from the student's user document
  Future<void> removeStudentFromClass(String classId, String studentId) async {
    try {
      // Get class document
      final classDoc =
          await _firestore.collection(_classesCollection).doc(classId).get();

      if (!classDoc.exists) {
        throw Exception('Classroom not found');
      }

      final classData = ClassModel.fromJson(classDoc.data()!);

      // Remove student from list
      final updatedStudentIds = classData.studentIds
          .where((id) => id != studentId)
          .toList();

      await _firestore.collection(_classesCollection).doc(classId).update({
        'studentIds': updatedStudentIds,
        'updatedAt': Timestamp.now(),
      });

      // Remove classId from student's user document
      await _firestore.collection(_usersCollection).doc(studentId).update({
        'classId': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to remove student from classroom: $e');
    }
  }

  /// Get all classrooms for a specific teacher
  Future<List<ClassModel>> getTeacherClasses(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_classesCollection)
          .where('teacherId', isEqualTo: teacherId)
          .get();

      // Sort on the client side instead of using orderBy
      // This avoids needing a Firestore composite index
      final classes = querySnapshot.docs
          .map((doc) => ClassModel.fromJson(doc.data()))
          .toList();

      // Sort by createdAt descending (newest first)
      classes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return classes;
    } catch (e) {
      throw Exception('Failed to get teacher classes: $e');
    }
  }

  /// Get the classroom for a specific student
  /// Returns null if student is not assigned to any classroom
  Future<ClassModel?> getStudentClass(String studentId) async {
    try {
      // First get student's classId from their user document
      final userDoc =
          await _firestore.collection(_usersCollection).doc(studentId).get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data();
      final classId = userData?['classId'] as String?;

      if (classId == null) {
        return null; // Student not assigned to any classroom
      }

      // Get the classroom document
      final classDoc =
          await _firestore.collection(_classesCollection).doc(classId).get();

      if (!classDoc.exists) {
        return null;
      }

      return ClassModel.fromJson(classDoc.data()!);
    } catch (e) {
      throw Exception('Failed to get student classroom: $e');
    }
  }

  /// Stream of teacher's classrooms (real-time updates)
  Stream<List<ClassModel>> teacherClassesStream(String teacherId) {
    try {
      return _firestore
          .collection(_classesCollection)
          .where('teacherId', isEqualTo: teacherId)
          .snapshots()
          .map((snapshot) {
        // Sort on the client side instead of using orderBy
        // This avoids needing a Firestore composite index
        final classes = snapshot.docs
            .map((doc) => ClassModel.fromJson(doc.data()))
            .toList();

        // Sort by createdAt descending (newest first)
        classes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return classes;
      });
    } catch (e) {
      throw Exception('Failed to stream teacher classes: $e');
    }
  }

  /// Get a single classroom by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final doc =
          await _firestore.collection(_classesCollection).doc(classId).get();

      if (!doc.exists) {
        return null;
      }

      return ClassModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get classroom: $e');
    }
  }

  /// Update classroom details
  Future<void> updateClass(ClassModel classData) async {
    try {
      final classWithTimestamp = classData.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_classesCollection)
          .doc(classData.id)
          .update(classWithTimestamp.toJson());
    } catch (e) {
      throw Exception('Failed to update classroom: $e');
    }
  }

  /// Delete a classroom
  Future<void> deleteClass(String classId) async {
    try {
      print('🔵 Deleting classroom: $classId');

      // Get class data first to remove classId from all students
      final classDoc =
          await _firestore.collection(_classesCollection).doc(classId).get();

      if (classDoc.exists) {
        final classData = ClassModel.fromJson(classDoc.data()!);
        print('✅ Classroom found: ${classData.name}, students: ${classData.studentIds.length}');

        // Remove classId from all students in this classroom
        for (final studentId in classData.studentIds) {
          print('🔄 Removing classId from student: $studentId');
          await _firestore.collection(_usersCollection).doc(studentId).update({
            'classId': FieldValue.delete(),
            'updatedAt': Timestamp.now(),
          });
        }
        print('✅ Removed classId from all students');
      }

      // Delete the classroom document
      print('🔄 Deleting classroom document');
      await _firestore.collection(_classesCollection).doc(classId).delete();
      print('✅ Classroom deleted successfully');
    } catch (e) {
      print('❌ Error deleting classroom: $e');
      throw Exception('Failed to delete classroom: $e');
    }
  }

  /// Create a new student and add them to a classroom (for teachers)
  /// The teacher must own the classroom to create students for it
  Future<UserModel> createStudentForClass({
    required String classId,
    required String email,
    required String password,
    required String fullName,
    required String userName,
    required String parentFullName,
    required String parentPhone,
    String? parentEmail,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Teacher must be logged in to create students');
    }

    try {
      // Get the classroom to verify ownership and get school info
      final classDoc =
          await _firestore.collection(_classesCollection).doc(classId).get();

      if (!classDoc.exists) {
        throw Exception('Classroom not found');
      }

      final classData = ClassModel.fromJson(classDoc.data()!);

      // Verify the current user is the teacher of this classroom
      if (classData.teacherId != currentUser.uid) {
        throw Exception('Only the classroom teacher can create students');
      }

      print('🔵 Creating student for classroom: ${classData.name}');

      // Create the user account in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUserUid = userCredential.user!.uid;
      print('✅ Firebase Auth user created: $newUserUid');

      // Create student data with classroom info pre-filled
      final userData = UserModel(
        id: newUserUid,
        userName: userName,
        fullName: fullName,
        email: email,
        role: 'student',
        schoolName: classData.schoolName,
        city: '', // Can be updated later
        grade: classData.grade,
        classId: classId, // Automatically assign to the classroom
        createdAt: DateTime.now(),
        parentFullName: parentFullName,
        parentPhone: parentPhone,
        parentEmail: parentEmail,
        xpPoints: 0,
        currentLevel: 1,
        currentStreak: 0,
        longestStreak: 0,
        xpHistory: {},
        completedLessons: [],
      );

      // Save student to Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(newUserUid)
          .set(userData.toJson());
      print('✅ Student document created in Firestore');

      // Add student to classroom's studentIds list
      final updatedStudentIds = [...classData.studentIds, newUserUid];
      await _firestore.collection(_classesCollection).doc(classId).update({
        'studentIds': updatedStudentIds,
        'updatedAt': Timestamp.now(),
      });
      print('✅ Student added to classroom');

      // Sign out newly created user (to keep teacher logged in)
      await _auth.signOut();
      print('✅ New user signed out');

      return userData;
    } catch (e) {
      print('❌ Error creating student: $e');
      throw Exception('Failed to create student: $e');
    }
  }
}
