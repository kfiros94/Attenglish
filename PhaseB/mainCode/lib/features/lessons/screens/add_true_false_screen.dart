import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity_model.dart';

/// Screen for creating a true or false activity
class AddTrueFalseScreen extends StatefulWidget {
  const AddTrueFalseScreen({super.key});

  @override
  State<AddTrueFalseScreen> createState() => _AddTrueFalseScreenState();
}

class _AddTrueFalseScreenState extends State<AddTrueFalseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _statementController = TextEditingController();
  final _pointsController = TextEditingController(text: '5');

  bool? _correctAnswer;

  @override
  void dispose() {
    _statementController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if correct answer is selected
    if (_correctAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select whether the statement is True or False'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create ActivityModel
    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'true_false',
      question: _statementController.text.trim(),
      correctAnswer: _correctAnswer,
      points: int.parse(_pointsController.text),
    );

    // Return to previous screen
    Navigator.pop(context, activity);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('True/False question added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('True or False Question'),
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
              // Statement Field
              TextFormField(
                controller: _statementController,
                decoration: const InputDecoration(
                  labelText: 'Statement *',
                  hintText: 'Dogs can fly.',
                  border: OutlineInputBorder(),
                  helperText: 'Enter a statement that is either true or false',
                  prefixIcon: Icon(Icons.question_answer),
                ),
                maxLength: 200,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Statement is required';
                  }
                  if (value.trim().length < 5) {
                    return 'Statement must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Correct Answer Selection
              Text(
                'Correct Answer *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select whether the statement above is true or false',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // True/False Buttons
              Row(
                children: [
                  // TRUE Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _correctAnswer = true;
                        });
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: _correctAnswer == true
                              ? Colors.green
                              : Colors.green.shade50,
                          border: Border.all(
                            color: _correctAnswer == true
                                ? Colors.green.shade700
                                : Colors.green.shade200,
                            width: _correctAnswer == true ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 48,
                              color: _correctAnswer == true
                                  ? Colors.white
                                  : Colors.green,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TRUE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _correctAnswer == true
                                    ? Colors.white
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // FALSE Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _correctAnswer = false;
                        });
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: _correctAnswer == false
                              ? Colors.orange
                              : Colors.orange.shade50,
                          border: Border.all(
                            color: _correctAnswer == false
                                ? Colors.orange.shade700
                                : Colors.orange.shade200,
                            width: _correctAnswer == false ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel,
                              size: 48,
                              color: _correctAnswer == false
                                  ? Colors.white
                                  : Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'FALSE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _correctAnswer == false
                                    ? Colors.white
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Save Question'),
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
