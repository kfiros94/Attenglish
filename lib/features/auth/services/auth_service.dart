import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Authentication service for managing user authentication and Firestore operations
/// Implements singleton pattern to ensure single instance across the app
class AuthService {
  // Private constructor for singleton
  AuthService._();

  // Singleton instance
  static final AuthService instance = AuthService._();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  static const String _usersCollection = 'users';

  /// Stream of authentication state changes
  /// Returns null when user is signed out, User object when signed in
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get currently signed-in user
  /// Returns null if no user is signed in
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password (for teachers, parents, and admins)
  ///
  /// Throws [FirebaseAuthException] if sign in fails
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign in with Ministry ID (for students)
  ///
  /// This is a placeholder implementation. In production, this should:
  /// 1. Call a Cloud Function to verify the ministry ID
  /// 2. The Cloud Function validates the ID and creates a custom token
  /// 3. Sign in with the custom token
  ///
  /// For now, this throws an unimplemented error
  Future<UserCredential> signInWithMinistryId(String ministryId) async {
    try {
      // TODO: Implement Cloud Function call
      // 1. Call Cloud Function: verifyMinistryId(ministryId)
      // 2. Receive custom token from Cloud Function
      // 3. Sign in with custom token:
      //    final credential = await _auth.signInWithCustomToken(customToken);
      //    return credential;

      throw UnimplementedError(
        'Ministry ID authentication requires Cloud Function implementation. '
        'This will be implemented in the backend.',
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in with Ministry ID: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Get user role from Firestore
  ///
  /// Returns the role string ('student', 'teacher', 'parent', 'admin')
  /// Returns null if user document doesn't exist or role field is missing
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      return data?['role'] as String?;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  /// Get complete user data from Firestore
  ///
  /// Returns UserModel if document exists
  /// Returns null if user document doesn't exist
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Create user document in Firestore
  ///
  /// Creates a new document with the user's UID as document ID
  /// Updates the updatedAt field automatically
  Future<void> createUserDocument(String uid, UserModel user) async {
    try {
      final userWithUpdatedTime = user.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userWithUpdatedTime.toJson());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Update user document in Firestore
  ///
  /// Updates existing user document and sets updatedAt to current time
  Future<void> updateUserDocument(String uid, UserModel user) async {
    try {
      final userWithUpdatedTime = user.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(userWithUpdatedTime.toJson());
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  /// Check if user document exists in Firestore
  Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user document: $e');
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many login attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        message = 'This sign-in method is not enabled.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email.';
        break;
      case 'invalid-credential':
        message = 'The credential is invalid or expired.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      default:
        message = 'Authentication failed: ${e.message ?? e.code}';
    }

    return Exception(message);
  }
}
