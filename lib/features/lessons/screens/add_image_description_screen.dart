import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity_model.dart';
import '../widgets/image_upload_widget.dart';

/// Screen for creating an image description activity
/// Teacher uploads 1-3 images and students describe them
/// Claude AI evaluates the descriptions
class AddImageDescriptionScreen extends StatefulWidget {
  const AddImageDescriptionScreen({super.key});

  @override
  State<AddImageDescriptionScreen> createState() => _AddImageDescriptionScreenState();
}

class _AddImageDescriptionScreenState extends State<AddImageDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _sampleAnswerController = TextEditingController();
  final _pointsController = TextEditingController(text: '20');

  List<String> _imageUrls = [];
  final String _tempLessonId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void dispose() {
    _questionController.dispose();
    _instructionsController.dispose();
    _sampleAnswerController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one image is uploaded
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create ActivityModel
    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'image_description',
      question: _questionController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      imageUrls: _imageUrls,
      sampleAnswer: _sampleAnswerController.text.trim().isEmpty
          ? null
          : _sampleAnswerController.text.trim(),
      points: int.parse(_pointsController.text),
    );

    // Return to previous screen
    Navigator.pop(context, activity);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image description activity added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Description'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveQuestion,
            tooltip: 'Save Activity',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '1. Upload 1-3 images\n'
                            '2. Students will describe what they see\n'
                            '3. AI evaluates grammar, vocabulary, and accuracy',
                            style: TextStyle(
                              color: Colors.purple.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Question/Prompt Field
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question/Prompt *',
                  hintText: 'Describe what you see in the image',
                  border: OutlineInputBorder(),
                  helperText: 'What should students do?',
                  prefixIcon: Icon(Icons.question_answer),
                ),
                maxLength: 200,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Question is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Instructions Field (optional)
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions (optional)',
                  hintText: 'Use full sentences. Mention colors, actions, and objects.',
                  border: OutlineInputBorder(),
                  helperText: 'Additional guidance for students',
                  prefixIcon: Icon(Icons.help_outline),
                ),
                maxLength: 300,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Image Upload Widget
              ImageUploadWidget(
                initialImageUrls: _imageUrls,
                lessonId: _tempLessonId,
                maxImages: 3,
                onImagesChanged: (urls) {
                  setState(() {
                    _imageUrls = urls;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Sample Answer Field (optional)
              TextFormField(
                controller: _sampleAnswerController,
                decoration: const InputDecoration(
                  labelText: 'Sample Answer (optional)',
                  hintText: 'A cat is sitting on a red chair in a sunny room.',
                  border: OutlineInputBorder(),
                  helperText: 'Example of a good description (for AI reference)',
                  prefixIcon: Icon(Icons.light_mode),
                ),
                maxLength: 500,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Points Field
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points *',
                  hintText: '20',
                  border: OutlineInputBorder(),
                  helperText: 'Points awarded for this activity',
                  prefixIcon: Icon(Icons.stars),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Points are required';
                  }
                  final points = int.tryParse(value);
                  if (points == null || points < 1 || points > 100) {
                    return 'Points must be between 1 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveQuestion,
                icon: const Icon(Icons.check),
                label: const Text('Save Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
