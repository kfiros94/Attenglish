import 'dart:io';
import 'dart:typed_data';
import '../../lessons/models/activity_model.dart';

/// Result returned when activities are generated from a document
/// Contains both the activities and the document metadata for upload
class ActivityResult {
  /// The selected activities
  final List<ActivityModel> activities;

  /// Document file (for mobile/desktop)
  final File? documentFile;

  /// Document bytes (for web)
  final Uint8List? documentBytes;

  /// Document filename
  final String? documentName;

  /// Document type (PDF, DOCX, TXT)
  final String? documentType;

  /// Extracted text from the document
  final String? sourceText;

  const ActivityResult({
    required this.activities,
    this.documentFile,
    this.documentBytes,
    this.documentName,
    this.documentType,
    this.sourceText,
  });

  /// Check if this result includes a document
  bool get hasDocument =>
      (documentFile != null || documentBytes != null) &&
      documentName != null &&
      documentType != null;
}
