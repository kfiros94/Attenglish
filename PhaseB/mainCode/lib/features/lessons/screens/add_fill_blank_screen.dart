import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity_model.dart';

/// Screen for creating a fill in the blank activity
class AddFillBlankScreen extends StatefulWidget {
  const AddFillBlankScreen({super.key});

  @override
  State<AddFillBlankScreen> createState() => _AddFillBlankScreenState();
}

class _AddFillBlankScreenState extends State<AddFillBlankScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sentenceController = TextEditingController();
  final _correctWordController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');

  @override
  void dispose() {
    _sentenceController.dispose();
    _correctWordController.dispose();
    _instructionsController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create ActivityModel
    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'fill_blank',
      question: 'Fill in the blank',
      blankSentence: _sentenceController.text.trim(),
      correctWord: _correctWordController.text.trim(),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      points: int.parse(_pointsController.text),
    );

    // Return to previous screen
    Navigator.pop(context, activity);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fill in the blank activity added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill in the Blank'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveQuestion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sentence with Blank Field
              TextFormField(
                controller: _sentenceController,
                decoration: const InputDecoration(
                  labelText: 'Sentence *',
                  hintText: 'The cat is _____ the table',
                  border: OutlineInputBorder(),
                  helperText: 'Use _____ where the word should go',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                maxLength: 200,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sentence is required';
                  }
                  if (!value.contains('_____')) {
                    return 'Sentence must contain _____ (5 underscores)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Correct Word Field
              TextFormField(
                controller: _correctWordController,
                decoration: const InputDecoration(
                  labelText: 'Missing Word *',
                  hintText: 'on',
                  border: OutlineInputBorder(),
                  helperText: 'The word that fills in the blank',
                  prefixIcon: Icon(Icons.check_circle),
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Missing word is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Instructions Field (optional)
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'Fill in the missing preposition',
                  border: OutlineInputBorder(),
                  helperText: 'Optional instructions for the student',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLength: 150,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Points Field
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  hintText: 'Points awarded for correct answer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Points are required';
                  }
                  final points = int.tryParse(value);
                  if (points == null || points < 1) {
                    return 'Points must be at least 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Action Buttons
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 16,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _saveQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Save Activity'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
