import 'package:flutter/material.dart';
import '../models/generation_config_model.dart';
import '../models/ai_response_model.dart';
import '../services/claude_ai_service.dart';
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
        final result = await Navigator.push<List<ActivityModel>>(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewActivitiesScreen(response: response),
          ),
        );

        // If activities were selected, return them
        if (result != null && result.isNotEmpty) {
          // Return the selected activities to the previous screen (lesson creator)
          Navigator.pop(context, result);
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

  /// Builds the "Upload File" tab (Coming Soon)
  Widget _buildUploadFileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Upload Document',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported: PDF, DOCX, TXT',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: null, // Disabled for now
            child: const Text('Coming in Next Update!'),
          ),
        ],
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
              onChanged: (value) => setState(() => _selectedGrade = value!),
            ),

            const SizedBox(height: 16),

            // Difficulty Level
            Text(
              'Difficulty',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              selected: {_selectedDifficulty},
              segments: const [
                ButtonSegment(
                  value: 'beginner',
                  label: Text('Beginner'),
                ),
                ButtonSegment(
                  value: 'intermediate',
                  label: Text('Intermediate'),
                ),
                ButtonSegment(
                  value: 'advanced',
                  label: Text('Advanced'),
                ),
              ],
              onSelectionChanged: (Set<String> selected) {
                setState(() => _selectedDifficulty = selected.first);
              },
            ),

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
}
