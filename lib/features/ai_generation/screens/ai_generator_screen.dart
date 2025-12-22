import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../models/generation_config_model.dart';
import '../models/ai_response_model.dart';
import '../models/activity_result_model.dart';
import '../services/claude_ai_service.dart';
import '../services/document_processor_service.dart';
import '../services/document_storage_service.dart';
import 'review_activities_screen.dart';
import '../../lessons/models/activity_model.dart';

/// Screen for generating AI-powered learning activities
///
/// Allows teachers to:
/// - Paste English text (50-5000 words)
/// - Upload documents (PDF, DOCX, TXT) - coming soon
/// - Configure generation settings (grade level, difficulty, activity types)
/// - Generate activities using Claude AI
///
/// The screen has two tabs:
/// 1. Paste Text - for direct text input
/// 2. Upload File - for document upload (coming soon)
class AiGeneratorScreen extends StatefulWidget {
  const AiGeneratorScreen({super.key});

  @override
  State<AiGeneratorScreen> createState() => _AiGeneratorScreenState();
}

class _AiGeneratorScreenState extends State<AiGeneratorScreen>
    with SingleTickerProviderStateMixin {
  // Tab controller for switching between paste/upload modes
  TabController? _tabController;

  // Text input controller
  final TextEditingController _textController = TextEditingController();

  // Generation configuration
  String _selectedGrade = '3rd';
  String _selectedDifficulty = 'beginner';
  int _mcCount = 5; // Multiple choice count
  int _fbCount = 3; // Fill blank count
  int _tfCount = 3; // True/false count
  int _ddCount = 2; // Drag & drop count
  bool _includeVocabulary = true;

  // State management
  bool _isGenerating = false;
  int _wordCount = 0;

  // Document upload variables
  File? _selectedFile;
  Uint8List? _selectedFileBytes; // For web platform
  DocumentExtractionResult? _extractedDocument;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);

    // Listen to text changes to update word count
    _textController.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _textController.dispose();
    _selectedFile = null;
    _extractedDocument = null;
    super.dispose();
  }

  /// Updates the word count from the text input
  void _updateWordCount() {
    final text = _textController.text.trim();
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    setState(() {
      _wordCount = words.length;
    });
  }

  /// Validates and generates activities from pasted text
  Future<void> _generateFromText() async {
    final text = _textController.text.trim();

    // Validate text is not empty
    if (text.isEmpty) {
      _showErrorSnackBar('Please enter some text to generate activities from.');
      return;
    }

    // Validate word count
    if (_wordCount < 50) {
      _showErrorSnackBar(
        'Text is too short. Please provide at least 50 words (you have $_wordCount).',
      );
      return;
    }

    if (_wordCount > 5000) {
      _showErrorSnackBar(
        'Text is too long. Maximum 5000 words allowed (you have $_wordCount).',
      );
      return;
    }

    // Create generation config
    final config = GenerationConfig(
      gradeLevel: _selectedGrade,
      difficulty: _selectedDifficulty,
      multipleChoiceCount: _mcCount,
      fillBlankCount: _fbCount,
      trueFalseCount: _tfCount,
      dragDropCount: _ddCount,
      includeVocabulary: _includeVocabulary,
    );

    // Generate activities
    await _generate(text, config);
  }

  /// Generates activities using Claude AI
  Future<void> _generate(String text, GenerationConfig config) async {
    setState(() {
      _isGenerating = true;
    });

    // Show loading dialog
    _showLoadingDialog();

    try {
      // Create AI service
      final service = ClaudeAiService.withDefaultKey();

      // Generate activities
      final response = await service.generateActivities(
        sourceText: text,
        config: config,
      );

      // Dispose service
      service.dispose();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Navigate to review screen
        print('=== NAVIGATING TO REVIEW SCREEN ===');
        print('=== extractedDocument: ${_extractedDocument != null}');
        print('=== extractedDocument.originalBytes: ${_extractedDocument?.originalBytes != null}');

        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewActivitiesScreen(
              response: response,
              extractedDocument: _extractedDocument,
            ),
          ),
        );

        print('=== BACK FROM REVIEW SCREEN ===');
        print('=== Result is null: ${result == null}');

        // If activities were selected, handle document upload and return
        if (result != null) {
          print('>>> RECEIVED RESULT FROM REVIEW SCREEN');
          print('>>> Result type: ${result.runtimeType}');
          print('>>> Result keys: ${result.keys}');

          final activities = result['activities'] as List<ActivityModel>?;
          final vocabulary = result['vocabulary'] as List<VocabularyItem>?;
          final extractedDoc = result['extractedDocument'] as DocumentExtractionResult?;

          print('>>> Activities: ${activities?.length ?? 0}');
          print('>>> Extracted doc: ${extractedDoc != null}');
          print('>>> Has originalBytes: ${extractedDoc?.originalBytes != null}');

          if (activities != null && activities.isNotEmpty) {
            print('>>> ACTIVITIES NOT EMPTY, PROCEEDING...');

            // Upload document to Firebase Storage if available
            String? documentUrl;
            String? documentName;
            String? documentType;

            if (extractedDoc != null && extractedDoc.originalBytes != null) {
              print('>>> STARTING UPLOAD PROCESS');
              try {
                print('>>> Uploading document to Firebase Storage...');

                // Show uploading message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Uploading document...'),
                      duration: Duration(seconds: 30),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }

                final storageService = DocumentStorageService();
                final tempLessonId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

                print('>>> Temp lesson ID: $tempLessonId');
                print('>>> Document name: ${extractedDoc.fileName}');
                print('>>> Bytes length: ${extractedDoc.originalBytes!.length}');

                documentUrl = await storageService.uploadDocument(
                  bytes: extractedDoc.originalBytes,
                  fileName: extractedDoc.fileName,
                  lessonId: tempLessonId,
                );

                documentName = extractedDoc.fileName;
                documentType = extractedDoc.fileType;

                print('>>> Upload successful! URL: $documentUrl');

                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Document uploaded successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('ERROR: Could not upload document: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Document upload failed, but activities saved'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            }

            // Return to previous screen with all data
            if (mounted) {
              Navigator.pop(context, {
                'activities': activities,
                'vocabulary': vocabulary,
                'sourceText': extractedDoc?.text,
                'sourceDocumentUrl': documentUrl,
                'sourceDocumentName': documentName,
                'sourceDocumentType': documentType,
              });
            }
          }
        }
      }
    } on AiGenerationException catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error dialog
      _showErrorDialog(e.message);
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show generic error
      _showErrorDialog('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  /// Shows enhanced loading dialog while generating
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated progress indicator
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'AI is working its magic... ✨',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Analyzing your text and creating activities',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Progress steps
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressStep(true, 'Reading content'),
                _buildProgressStep(true, 'Generating questions'),
                _buildProgressStep(false, 'Almost done...'),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'This usually takes 10-30 seconds',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a progress step indicator
  Widget _buildProgressStep(bool completed, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: completed ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: completed ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows success dialog with generation results
  void _showSuccessDialog(AiGenerationResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generated ${response.totalActivities} activities'),
            Text('Vocabulary: ${response.vocabulary.length} words'),
            Text('Total points: ${response.totalPoints}'),
            Text(
              'Generation time: ${response.generationTime.inSeconds}s',
            ),
            const SizedBox(height: 16),
            Text(
              response.summary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Picks and extracts text from a document
  Future<void> _pickAndExtractDocument() async {
    setState(() => _isExtracting = true);

    try {
      final service = DocumentProcessorService();

      // For mobile/desktop
      if (!kIsWeb) {
        final file = await service.pickDocument();

        if (file == null) {
          setState(() => _isExtracting = false);
          return;
        }

        final result = await service.extractTextFromFile(file);

        setState(() {
          _selectedFile = file;
          _extractedDocument = result;
          _isExtracting = false;
        });
      } else {
        // For web - handle bytes
        final pickerResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'docx', 'txt'],
          withData: true,
        );

        if (pickerResult == null || pickerResult.files.isEmpty) {
          setState(() => _isExtracting = false);
          return;
        }

        final fileBytes = pickerResult.files.first.bytes;
        final fileName = pickerResult.files.first.name;

        if (fileBytes == null) {
          throw DocumentProcessingException('Failed to read file data');
        }

        final result = await service.extractTextFromBytes(fileBytes, fileName);

        setState(() {
          _selectedFileBytes = fileBytes; // Store bytes for later upload
          _extractedDocument = result;
          _isExtracting = false;
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Text extracted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on DocumentProcessingException catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        // Show error dialog for better readability of multi-line errors
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Document Processing Error'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                e.message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isExtracting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Removes the currently selected document
  void _removeDocument() {
    setState(() {
      _selectedFile = null;
      _selectedFileBytes = null;
      _extractedDocument = null;
    });
  }

  /// Generates activities from the extracted document text
  Future<void> _generateFromDocument() async {
    if (_extractedDocument == null) return;

    // Validate document
    if (!_extractedDocument!.isValidLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractedDocument!.validationMessage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Build config from form
    final config = GenerationConfig(
      gradeLevel: _selectedGrade,
      difficulty: _selectedDifficulty,
      multipleChoiceCount: _mcCount,
      fillBlankCount: _fbCount,
      trueFalseCount: _tfCount,
      dragDropCount: _ddCount,
      includeVocabulary: _includeVocabulary,
    );

    // Use existing _generate method with extracted text
    await _generate(_extractedDocument!.text, config);
  }

  /// Shows enhanced help dialog with detailed instructions
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.purple),
            SizedBox(width: 8),
            Text('How to Use AI Generator'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                '1. Paste Your Text',
                'Copy any English text (50-5000 words). This could be:\n'
                '• A story or article\n'
                '• A lesson passage\n'
                '• Any educational content',
              ),
              _buildHelpSection(
                '2. Configure Settings',
                'Choose grade level and difficulty.\n'
                'Select how many of each activity type you want.',
              ),
              _buildHelpSection(
                '3. Generate',
                'Click "Generate Activities" and wait 10-30 seconds.\n'
                'AI will create ADHD-friendly activities from your text.',
              ),
              _buildHelpSection(
                '4. Review & Add',
                'Review generated activities.\n'
                'Edit, delete, or add them directly to your lesson!',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Use clear, well-written text for best results!',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  /// Builds a help section with title and content
  Widget _buildHelpSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Activity Generator ✨'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.text_fields),
              text: 'Paste Text',
            ),
            Tab(
              icon: Icon(Icons.upload_file),
              text: 'Upload File',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Paste Text
          _buildPasteTextTab(),

          // Tab 2: Upload Document (Coming Soon)
          _buildUploadFileTab(),
        ],
      ),
    );
  }

  /// Builds the "Paste Text" tab
  Widget _buildPasteTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paste English text (50-5000 words) and I\'ll generate activities for you!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Best for: stories, articles, passages',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Text input field
          TextFormField(
            controller: _textController,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: 'English Text',
              hintText: 'Paste your text here...',
              border: const OutlineInputBorder(),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _textController.clear();
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 8),

          // Word count indicator
          Text(
            'Word count: $_wordCount',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _wordCount >= 50 && _wordCount <= 5000
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 24),

          // Configuration section
          _buildConfigurationSection(),

          const SizedBox(height: 24),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateFromText,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Activities',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the "Upload File" tab
  Widget _buildUploadFileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upload a PDF, DOCX, or TXT file. AI will extract the text and generate activities!',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Upload button OR file info
          if (_extractedDocument == null)
            _buildUploadButton()
          else
            _buildFileInfo(),

          // Show rest only if document is uploaded
          if (_extractedDocument != null) ...[
            const SizedBox(height: 24),
            _buildTextPreview(),

            const SizedBox(height: 24),
            _buildConfigurationSection(),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateFromDocument,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Activities',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the upload button for document selection
  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isExtracting ? null : _pickAndExtractDocument,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isExtracting ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _isExtracting ? Colors.blue.shade50 : Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isExtracting)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Extracting text from document...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF, DOCX, or TXT',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickAndExtractDocument,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose File'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the file info card showing document details
  Widget _buildFileInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File header
            Row(
              children: [
                const Icon(Icons.description, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _extractedDocument!.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_extractedDocument!.fileType} • ${_extractedDocument!.fileSizeKB} KB',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removeDocument,
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove file',
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // File stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Words', _extractedDocument!.wordCount.toString()),
                if (_extractedDocument!.pageCount != null)
                  _buildStat('Pages', _extractedDocument!.pageCount.toString()),
                _buildStat('Size', '${_extractedDocument!.fileSizeMB} MB'),
              ],
            ),

            const SizedBox(height: 12),

            // Validation status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _extractedDocument!.isValidLength
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _extractedDocument!.isValidLength
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _extractedDocument!.isValidLength
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _extractedDocument!.validationMessage,
                      style: TextStyle(
                        color: _extractedDocument!.isValidLength
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a stat display (helper for file info)
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Builds the text preview widget showing extracted text
  Widget _buildTextPreview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Extracted Text Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _extractedDocument!.text.length > 500
                      ? '${_extractedDocument!.text.substring(0, 500)}...\n\n(Preview truncated. Full text will be used for generation.)'
                      : _extractedDocument!.text,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the configuration section for generation settings
  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Generation Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Grade Level
            Text(
              'Grade Level',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGrade,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                '1st',
                '2nd',
                '3rd',
                '4th',
                '5th',
                '6th',
                '7th',
                '8th',
                '9th',
                '10th',
                '11th',
                '12th'
              ]
                  .map((grade) => DropdownMenuItem(
                        value: grade,
                        child: Text(grade),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGrade = value!;
                  // Auto-set difficulty for grades 1-9 (grade-based)
                  // For grades 10-12, keep current selection
                  final gradeNum = int.tryParse(value.replaceAll(RegExp(r'\D'), ''));
                  if (gradeNum != null && gradeNum >= 1 && gradeNum <= 9) {
                    // For grades 1-9, difficulty is ignored (grade determines difficulty)
                    // Set to 'beginner' as placeholder, won't be used in AI prompt
                    _selectedDifficulty = 'beginner';
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // Difficulty Level - Only show for grades 10-12
            if (_isHighSchoolGrade())
              ...[
                Text(
                  'Difficulty Level',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  selected: {_selectedDifficulty},
                  segments: const [
                    ButtonSegment(
                      value: 'beginner',
                      label: Text('Normal'),
                    ),
                    ButtonSegment(
                      value: 'intermediate',
                      label: Text('Hard'),
                    ),
                    ButtonSegment(
                      value: 'advanced',
                      label: Text('Very Hard'),
                    ),
                  ],
                  onSelectionChanged: (Set<String> selected) {
                    setState(() => _selectedDifficulty = selected.first);
                  },
                ),
                const SizedBox(height: 16),
              ]
            else
              ...[
                // Show info message for grades 1-9
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Difficulty automatically matches $_selectedGrade grade level',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[700],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

            const SizedBox(height: 16),

            // Activity Types
            Text(
              'Activity Types',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCountSelector(
                    'Multiple Choice',
                    _mcCount,
                    (val) => setState(() => _mcCount = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountSelector(
                    'Fill Blank',
                    _fbCount,
                    (val) => setState(() => _fbCount = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCountSelector(
                    'True/False',
                    _tfCount,
                    (val) => setState(() => _tfCount = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountSelector(
                    'Drag & Drop',
                    _ddCount,
                    (val) => setState(() => _ddCount = val),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Include Vocabulary
            SwitchListTile(
              title: const Text('Include Vocabulary'),
              subtitle: const Text('Extract key words with Hebrew translations'),
              value: _includeVocabulary,
              onChanged: (value) => setState(() => _includeVocabulary = value),
              contentPadding: EdgeInsets.zero,
            ),

            // Show total
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Activities:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_mcCount + _fbCount + _tfCount + _ddCount}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a count selector widget for activity types
  Widget _buildCountSelector(
    String label,
    int value,
    Function(int) onChanged,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: value > 0 ? () => onChanged(value - 1) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: value < 10 ? () => onChanged(value + 1) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Checks if the currently selected grade is high school (10-12)
  /// Returns true for grades 10-12, false for grades 1-9
  bool _isHighSchoolGrade() {
    final gradeNum = int.tryParse(_selectedGrade.replaceAll(RegExp(r'\D'), ''));
    return gradeNum != null && gradeNum >= 10;
  }
}
