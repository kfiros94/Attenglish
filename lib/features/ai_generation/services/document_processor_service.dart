import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

/// Service for processing document files (PDF, DOCX, TXT)
/// and extracting text content for AI generation
class DocumentProcessorService {
  /// Pick a document file from the device
  /// Returns null if user cancels or no file is selected
  Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        allowMultiple: false,
        withData: kIsWeb, // Important for web support
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      // For mobile/desktop, return File
      if (!kIsWeb) {
        final filePath = result.files.first.path;
        if (filePath == null) return null;
        return File(filePath);
      }

      // For web, we'll handle bytes separately
      return null;
    } catch (e) {
      throw DocumentProcessingException('Failed to pick file: $e');
    }
  }

  /// Extract text from a file
  /// Throws DocumentProcessingException if extraction fails
  /// Throws UnsupportedFileException if file type is not supported
  Future<DocumentExtractionResult> extractTextFromFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return await _extractFromPdf(file);

      case 'docx':
        return await _extractFromDocx(file);

      case 'txt':
        try {
          final text = await file.readAsString();
          final wordCount = text.isEmpty
              ? 0
              : text.trim().split(RegExp(r'\s+')).length;
          final fileSize = await file.length();

          return DocumentExtractionResult(
            text: text,
            pageCount: null,
            wordCount: wordCount,
            fileSize: fileSize,
            fileName: file.path.split('/').last,
            fileType: 'TXT',
          );
        } catch (e) {
          throw DocumentProcessingException('Failed to read text file: $e');
        }

      default:
        throw UnsupportedFileException('Unsupported file type: $extension');
    }
  }

  /// Extract text from bytes (useful for web platform)
  /// Throws DocumentProcessingException if extraction fails
  /// Throws UnsupportedFileException if file type is not supported
  Future<DocumentExtractionResult> extractTextFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return await _extractFromPdfBytes(bytes, fileName);

      case 'docx':
        return await _extractFromDocxBytes(bytes, fileName);

      case 'txt':
        try {
          final text = String.fromCharCodes(bytes);
          final wordCount = text.isEmpty
              ? 0
              : text.trim().split(RegExp(r'\s+')).length;

          return DocumentExtractionResult(
            text: text,
            pageCount: null,
            wordCount: wordCount,
            fileSize: bytes.length,
            fileName: fileName,
            fileType: 'TXT',
          );
        } catch (e) {
          throw DocumentProcessingException('Failed to read text file: $e');
        }

      default:
        throw UnsupportedFileException('Unsupported file type: $extension');
    }
  }

  /// Extract text from a PDF file
  Future<DocumentExtractionResult> _extractFromPdf(File file) async {
    try {
      // Load PDF from file
      final bytes = await file.readAsBytes();
      return await _extractFromPdfBytes(bytes, file.path.split('/').last);
    } catch (e) {
      throw DocumentProcessingException('Failed to read PDF file: $e');
    }
  }

  /// Extract text from PDF bytes
  Future<DocumentExtractionResult> _extractFromPdfBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      final StringBuffer textBuffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final String pageText = PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        textBuffer.writeln(pageText);
        textBuffer.writeln(); // Space between pages
      }

      final extractedText = textBuffer.toString().trim();

      // Count words
      final wordCount = extractedText.isEmpty
          ? 0
          : extractedText.trim().split(RegExp(r'\s+')).length;

      // Get page count before disposing
      final pageCount = document.pages.count;

      // Clean up
      document.dispose();

      return DocumentExtractionResult(
        text: extractedText,
        pageCount: pageCount,
        wordCount: wordCount,
        fileSize: bytes.length,
        fileName: fileName,
        fileType: 'PDF',
      );
    } catch (e) {
      throw DocumentProcessingException('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text from a DOCX file
  Future<DocumentExtractionResult> _extractFromDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await _extractFromDocxBytes(bytes, file.path.split('/').last);
    } catch (e) {
      throw DocumentProcessingException('Failed to read DOCX file: $e');
    }
  }

  /// Extract text from DOCX bytes
  Future<DocumentExtractionResult> _extractFromDocxBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      Archive archive;

      // Try to decode the ZIP archive
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      } catch (zipError) {
        throw DocumentProcessingException(
          'Invalid DOCX file: Unable to read file structure. '
          'The file may be corrupted or not a valid DOCX document. '
          'Please try:\n'
          '1. Opening the file in Microsoft Word/Google Docs\n'
          '2. Saving it again as DOCX\n'
          '3. Or converting it to PDF format\n'
          'Technical error: $zipError'
        );
      }

      // Find document.xml which contains the text
      final documentXml = archive.findFile('word/document.xml');

      if (documentXml == null) {
        // List available files for debugging
        final availableFiles = archive.files.map((f) => f.name).join(', ');
        throw DocumentProcessingException(
          'Invalid DOCX file: Required content not found. '
          'This file may not be a valid Word document. '
          'Available files in archive: $availableFiles'
        );
      }

      // Extract the XML content
      String xmlContent;
      try {
        xmlContent = String.fromCharCodes(documentXml.content as List<int>);
      } catch (e) {
        throw DocumentProcessingException(
          'Failed to read document content. The file may be corrupted.'
        );
      }

      // Extract text from XML
      final text = _extractTextFromXml(xmlContent);

      if (text.isEmpty) {
        throw DocumentProcessingException(
          'No text found in document. The document may be empty or contain only images.'
        );
      }

      // Count words
      final wordCount = text.trim().split(RegExp(r'\s+')).length;

      return DocumentExtractionResult(
        text: text,
        pageCount: null, // DOCX doesn't have fixed pages
        wordCount: wordCount,
        fileSize: bytes.length,
        fileName: fileName,
        fileType: 'DOCX',
      );
    } on DocumentProcessingException {
      // Re-throw our custom exceptions
      rethrow;
    } catch (e) {
      // Catch any other unexpected errors
      throw DocumentProcessingException(
        'Unexpected error while processing DOCX file: $e\n\n'
        'Please try:\n'
        '1. Re-saving the document in Word/Google Docs\n'
        '2. Converting to PDF format instead\n'
        '3. Using a different document'
      );
    }
  }

  /// Extract text content from Word XML
  String _extractTextFromXml(String xmlContent) {
    // Simple XML text extraction
    // Find all text between <w:t> tags
    final textRegex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
    final matches = textRegex.allMatches(xmlContent);

    final StringBuffer textBuffer = StringBuffer();

    for (final match in matches) {
      if (match.group(1) != null) {
        textBuffer.write(match.group(1));
        textBuffer.write(' ');
      }
    }

    return textBuffer.toString().trim();
  }
}

/// Result of document text extraction
class DocumentExtractionResult {
  /// Extracted text content
  final String text;

  /// Number of pages (for PDF files, null for others)
  final int? pageCount;

  /// Number of words in the text
  final int wordCount;

  /// File size in bytes
  final int fileSize;

  /// Original file name
  final String fileName;

  /// File type (extension)
  final String fileType;

  const DocumentExtractionResult({
    required this.text,
    this.pageCount,
    required this.wordCount,
    required this.fileSize,
    required this.fileName,
    required this.fileType,
  });

  /// Get file size in MB with 2 decimal places
  String get fileSizeMB {
    return (fileSize / (1024 * 1024)).toStringAsFixed(2);
  }

  /// Get file size in KB with no decimal places
  String get fileSizeKB {
    return (fileSize / 1024).toStringAsFixed(0);
  }

  /// Check if file size is within limits (max 10MB)
  bool get isValidSize {
    return fileSize <= 10 * 1024 * 1024; // 10MB max
  }

  /// Check if text length is within limits (50-5000 words)
  bool get isValidLength {
    return wordCount >= 50 && wordCount <= 5000;
  }

  /// Get validation message based on file size and text length
  String get validationMessage {
    if (!isValidSize) return 'File too large (max 10MB)';
    if (wordCount < 50) return 'Text too short (minimum 50 words)';
    if (wordCount > 5000) return 'Text too long (maximum 5000 words)';
    return 'File is ready for processing!';
  }
}

/// Exception thrown when document processing fails
class DocumentProcessingException implements Exception {
  final String message;

  DocumentProcessingException(this.message);

  @override
  String toString() => 'DocumentProcessingException: $message';
}

/// Exception thrown when file type is not supported
class UnsupportedFileException implements Exception {
  final String message;

  UnsupportedFileException(this.message);

  @override
  String toString() => 'UnsupportedFileException: $message';
}
