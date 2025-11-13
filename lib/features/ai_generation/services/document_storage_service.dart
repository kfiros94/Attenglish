import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for uploading and managing documents in Firebase Storage
class DocumentStorageService {
  /// Upload a document to Firebase Storage
  ///
  /// Parameters:
  /// - [file]: File object for mobile/desktop platforms
  /// - [bytes]: Uint8List for web platform
  /// - [fileName]: Original file name
  /// - [lessonId]: Lesson ID for organizing files
  ///
  /// Returns: Download URL of the uploaded document
  Future<String> uploadDocument({
    File? file,
    Uint8List? bytes,
    required String fileName,
    required String lessonId,
  }) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('lessons')
          .child(lessonId)
          .child('documents')
          .child(uniqueFileName);

      UploadTask uploadTask;

      // Upload based on platform
      if (kIsWeb && bytes != null) {
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: _getContentType(fileName),
          ),
        );
      } else if (file != null) {
        uploadTask = storageRef.putFile(
          file,
          SettableMetadata(
            contentType: _getContentType(fileName),
          ),
        );
      } else {
        throw Exception('No file or bytes provided for upload');
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Delete a document from Firebase Storage
  ///
  /// Parameters:
  /// - [downloadUrl]: The download URL of the document to delete
  Future<void> deleteDocument(String downloadUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail - document might already be deleted
      print('Warning: Could not delete document: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
