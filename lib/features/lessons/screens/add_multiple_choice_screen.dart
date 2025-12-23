import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/activity_model.dart';

/// Screen for creating multiple choice questions
class AddMultipleChoiceScreen extends StatefulWidget {
  const AddMultipleChoiceScreen({super.key});

  @override
  State<AddMultipleChoiceScreen> createState() =>
      _AddMultipleChoiceScreenState();
}

class _AddMultipleChoiceScreenState extends State<AddMultipleChoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _pointsController = TextEditingController(text: '10');

  int? _correctAnswerIndex;
  Set<int> _correctAnswerIndices = {};
  bool _isMultipleAnswers = false;

  @override
  void dispose() {
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check correct answer selected
    if (_isMultipleAnswers) {
      if (_correctAnswerIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one correct answer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_correctAnswerIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the correct answer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Create ActivityModel
    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'multiple_choice',
      question: _questionController.text.trim(),
      options: [
        _option1Controller.text.trim(),
        _option2Controller.text.trim(),
        _option3Controller.text.trim(),
        _option4Controller.text.trim(),
      ],
      correctAnswerIndex: _isMultipleAnswers ? null : _correctAnswerIndex,
      correctAnswerIndices: _isMultipleAnswers ? (_correctAnswerIndices.toList()..sort()) : null,
      points: int.parse(_pointsController.text),
    );

    // Return the activity to previous screen
    Navigator.pop(context, activity);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Choice Question'),
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
              // Question Field
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question *',
                  hintText: 'What color is the sky?',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the main question',
                ),
                maxLength: 200,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Question is required';
                  }
                  if (value.trim().length < 5) {
                    return 'Question must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Option 1
              TextFormField(
                controller: _option1Controller,
                decoration: const InputDecoration(
                  labelText: 'Option 1 *',
                  hintText: 'First answer option',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.looks_one),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Option 1 is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Option 2
              TextFormField(
                controller: _option2Controller,
                decoration: const InputDecoration(
                  labelText: 'Option 2 *',
                  hintText: 'Second answer option',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.looks_two),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Option 2 is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Option 3
              TextFormField(
                controller: _option3Controller,
                decoration: const InputDecoration(
                  labelText: 'Option 3 *',
                  hintText: 'Third answer option',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.looks_3),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Option 3 is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Option 4
              TextFormField(
                controller: _option4Controller,
                decoration: const InputDecoration(
                  labelText: 'Option 4 *',
                  hintText: 'Fourth answer option',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.looks_4),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Option 4 is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Multiple answers toggle
              SwitchListTile(
                title: const Text('Multiple Correct Answers'),
                subtitle: const Text('Allow more than one correct answer'),
                value: _isMultipleAnswers,
                onChanged: (value) {
                  setState(() {
                    _isMultipleAnswers = value;
                    if (_isMultipleAnswers && _correctAnswerIndex != null) {
                      // Convert single answer to multiple
                      _correctAnswerIndices = {_correctAnswerIndex!};
                    } else if (!_isMultipleAnswers && _correctAnswerIndices.isNotEmpty) {
                      // Convert multiple to single
                      _correctAnswerIndex = _correctAnswerIndices.first;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Correct Answer Selection
              Text(
                'Correct Answer *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isMultipleAnswers
                    ? 'Select all correct answers'
                    : 'Select which option is the correct answer',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              // Option 1
              Card(
                color: Colors.blue.shade50,
                child: _isMultipleAnswers
                    ? CheckboxListTile(
                        title: const Text('Option 1'),
                        value: _correctAnswerIndices.contains(0),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _correctAnswerIndices.add(0);
                            } else {
                              _correctAnswerIndices.remove(0);
                            }
                          });
                        },
                      )
                    : RadioListTile<int>(
                        title: const Text('Option 1'),
                        value: 0,
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          setState(() {
                            _correctAnswerIndex = value;
                          });
                        },
                      ),
              ),
              const SizedBox(height: 8),

              // Option 2
              Card(
                color: Colors.blue.shade50,
                child: _isMultipleAnswers
                    ? CheckboxListTile(
                        title: const Text('Option 2'),
                        value: _correctAnswerIndices.contains(1),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _correctAnswerIndices.add(1);
                            } else {
                              _correctAnswerIndices.remove(1);
                            }
                          });
                        },
                      )
                    : RadioListTile<int>(
                        title: const Text('Option 2'),
                        value: 1,
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          setState(() {
                            _correctAnswerIndex = value;
                          });
                        },
                      ),
              ),
              const SizedBox(height: 8),

              // Option 3
              Card(
                color: Colors.blue.shade50,
                child: _isMultipleAnswers
                    ? CheckboxListTile(
                        title: const Text('Option 3'),
                        value: _correctAnswerIndices.contains(2),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _correctAnswerIndices.add(2);
                            } else {
                              _correctAnswerIndices.remove(2);
                            }
                          });
                        },
                      )
                    : RadioListTile<int>(
                        title: const Text('Option 3'),
                        value: 2,
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          setState(() {
                            _correctAnswerIndex = value;
                          });
                        },
                      ),
              ),
              const SizedBox(height: 8),

              // Option 4
              Card(
                color: Colors.blue.shade50,
                child: _isMultipleAnswers
                    ? CheckboxListTile(
                        title: const Text('Option 4'),
                        value: _correctAnswerIndices.contains(3),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _correctAnswerIndices.add(3);
                            } else {
                              _correctAnswerIndices.remove(3);
                            }
                          });
                        },
                      )
                    : RadioListTile<int>(
                        title: const Text('Option 4'),
                        value: 3,
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          setState(() {
                            _correctAnswerIndex = value;
                    });
                  },
                  ),
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
                      backgroundColor: Colors.blue,
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
