import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/models/user_model.dart';

/// Service for admin operations
/// Singleton pattern for global access
class AdminService {
  static final AdminService _instance = AdminService._internal();
  static AdminService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AdminService._internal();

  /// Check if current user is admin
  Future<bool> isAdmin(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] as String?;
        return role == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Create a user account (admin only) - can be teacher or admin
  /// Returns the created user's UserModel
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required String userName,
    required String role, // 'teacher' or 'admin'
    String? schoolName,
    String? city,
  }) async {
    // Note: In production, you'd want to use Firebase Admin SDK on the backend
    // For now, we'll create the account using the regular Firebase Auth
    // The admin will need to temporarily sign out and back in after creation

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Admin must be logged in to create users');
    }

    // Verify admin status
    final isAdminUser = await isAdmin(currentUser.uid);
    if (!isAdminUser) {
      throw Exception('Only admins can create user accounts');
    }

    try {
      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUserUid = userCredential.user!.uid;

      // Create user data
      final userData = UserModel(
        id: newUserUid,
        userName: userName,
        fullName: fullName,
        email: email,
        role: role,
        schoolName: schoolName ?? '',
        city: city ?? '',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(newUserUid)
          .set(userData.toJson());

      // Sign back in as admin
      // Note: This will sign out the newly created user
      // In production, use Firebase Admin SDK to avoid this
      await _auth.signOut();

      return userData;
    } catch (e) {
      throw Exception('Failed to create user account: $e');
    }
  }

  /// Convenience method to create a teacher
  Future<UserModel> createTeacher({
    required String email,
    required String password,
    required String fullName,
    required String userName,
    required String schoolName,
    required String city,
  }) {
    return createUser(
      email: email,
      password: password,
      fullName: fullName,
      userName: userName,
      role: 'teacher',
      schoolName: schoolName,
      city: city,
    );
  }

  /// Convenience method to create an admin
  Future<UserModel> createAdmin({
    required String email,
    required String password,
    required String fullName,
    required String userName,
  }) {
    return createUser(
      email: email,
      password: password,
      fullName: fullName,
      userName: userName,
      role: 'admin',
      schoolName: 'N/A',
      city: 'N/A',
    );
  }

  /// Get all teachers (admin only)
  Future<List<UserModel>> getAllTeachers(String adminUid) async {
    final isAdminUser = await isAdmin(adminUid);
    if (!isAdminUser) {
      throw Exception('Only admins can view all teachers');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to load teachers: $e');
    }
  }

  /// Stream of all teachers (admin only)
  Stream<List<UserModel>> teachersStream(String adminUid) async* {
    final isAdminUser = await isAdmin(adminUid);
    if (!isAdminUser) {
      throw Exception('Only admins can view all teachers');
    }

    yield* _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList());
  }

  /// Delete teacher account (admin only)
  Future<void> deleteTeacher(String adminUid, String teacherId) async {
    final isAdminUser = await isAdmin(adminUid);
    if (!isAdminUser) {
      throw Exception('Only admins can delete teachers');
    }

    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(teacherId).delete();

      // Note: Deleting from Firebase Auth requires Admin SDK on backend
      // For now, we only delete from Firestore
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }
}
