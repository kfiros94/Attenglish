import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../classroom/services/class_service.dart';
import '../../classroom/models/class_model.dart';
import '../../auth/services/auth_service.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';

/// Screen for creating and editing lessons
/// Professional web form with validation
class CreateLessonScreen extends StatefulWidget {
  final String? lessonId; // null for create, non-null for edit

  const CreateLessonScreen({
    super.key,
    this.lessonId,
  });

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _topicController = TextEditingController();
  final _contentController = TextEditingController();

  String? _selectedClassId;
  int? _selectedGrade;
  int? _selectedDifficulty;

  bool _isLoading = false;
  bool _isLoadingData = true;
  List<ClassModel> _teacherClasses = [];
  LessonModel? _existingLesson;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Load teacher's classes and existing lesson (if editing)
  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);

    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      // Load teacher's classes
      _teacherClasses = await ClassService.instance.getTeacherClasses(user.uid);

      // If editing, load existing lesson
      if (widget.lessonId != null) {
        _existingLesson =
            await LessonService.instance.getLesson(widget.lessonId!);

        if (_existingLesson != null) {
          _titleController.text = _existingLesson!.title;
          _descriptionController.text = _existingLesson!.description ?? '';
          _topicController.text = _existingLesson!.topic ?? '';
          _contentController.text = _existingLesson!.textContent;
          _selectedClassId = _existingLesson!.classId;
          _selectedGrade = _existingLesson!.grade;
          _selectedDifficulty = _existingLesson!.difficulty;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  /// Save lesson as draft
  Future<void> _saveAsDraft() async {
    await _saveLesson(status: 'draft');
  }

  /// Publish lesson
  Future<void> _publish() async {
    await _saveLesson(status: 'published');
  }

  /// Save lesson with specified status
  Future<void> _saveLesson({required String status}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a classroom'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a grade level'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDifficulty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a difficulty level'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final lesson = LessonModel(
        id: _existingLesson?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        classId: _selectedClassId!,
        teacherId: user.uid,
        grade: _selectedGrade!,
        difficulty: _selectedDifficulty!,
        topic: _topicController.text.trim().isEmpty
            ? null
            : _topicController.text.trim(),
        textContent: _contentController.text.trim(),
        createdAt: _existingLesson?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        status: status,
      );

      if (widget.lessonId != null) {
        // Update existing lesson
        await LessonService.instance.updateLesson(widget.lessonId!, lesson);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'published'
                    ? 'Lesson published successfully!'
                    : 'Lesson saved as draft!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Create new lesson
        final lessonId = await LessonService.instance.createLesson(lesson);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'published'
                    ? 'Lesson created and published!'
                    : 'Lesson created as draft!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lessonId != null ? 'Edit Lesson' : 'Create New Lesson',
        ),
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Page header
                        Text(
                          widget.lessonId != null
                              ? 'Edit your lesson details'
                              : 'Create a new lesson for your students',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 32),

                        // Title field
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Lesson Title *',
                            hintText: 'e.g., Introduction to Present Tense',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          maxLength: 100,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            if (value.trim().length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Description field
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText:
                                'Brief description of what students will learn',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                          maxLength: 300,
                        ),
                        const SizedBox(height: 20),

                        // Classroom dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Classroom *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          items: _teacherClasses.map((classroom) {
                            return DropdownMenuItem(
                              value: classroom.id,
                              child: Text(classroom.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedClassId = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a classroom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Grade and Difficulty row
                        Row(
                          children: [
                            // Grade dropdown
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedGrade,
                                decoration: const InputDecoration(
                                  labelText: 'Grade Level *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.school),
                                ),
                                items: List.generate(12, (index) {
                                  final grade = index + 1;
                                  return DropdownMenuItem(
                                    value: grade,
                                    child: Text('Grade $grade'),
                                  );
                                }),
                                onChanged: (value) {
                                  setState(() => _selectedGrade = value);
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Select grade';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Difficulty dropdown
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedDifficulty,
                                decoration: const InputDecoration(
                                  labelText: 'Difficulty *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.signal_cellular_alt),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 1, child: Text('Easy')),
                                  DropdownMenuItem(
                                      value: 2, child: Text('Medium')),
                                  DropdownMenuItem(
                                      value: 3, child: Text('Hard')),
                                  DropdownMenuItem(
                                      value: 4, child: Text('Very Hard')),
                                  DropdownMenuItem(
                                      value: 5, child: Text('Expert')),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedDifficulty = value);
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Select difficulty';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Topic field
                        TextFormField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            labelText: 'Topic (Optional)',
                            hintText: 'e.g., Grammar, Vocabulary, Reading',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.topic),
                          ),
                          maxLength: 100,
                        ),
                        const SizedBox(height: 20),

                        // Content field (large)
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            labelText: 'Lesson Content *',
                            hintText:
                                'Write the main lesson content here...\n\nYou can include:\n- Explanations\n- Examples\n- Rules\n- Tips',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 15,
                          minLines: 10,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter lesson content';
                            }
                            if (value.trim().length < 10) {
                              return 'Content must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Action buttons
                        Row(
                          children: [
                            // Cancel button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Save as Draft button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _saveAsDraft,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text('Save as Draft'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Publish button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _publish,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.publish),
                                label: const Text('Publish'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
