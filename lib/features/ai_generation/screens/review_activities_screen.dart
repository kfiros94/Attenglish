import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_response_model.dart';
import '../../lessons/models/activity_model.dart';
import '../../lessons/models/lesson_model.dart';
import '../../lessons/services/lesson_service.dart';
import '../../classroom/services/class_service.dart';
import '../../classroom/models/class_model.dart';
import '../services/document_processor_service.dart';
import '../services/document_storage_service.dart';

/// Screen for reviewing AI-generated activities before adding to lesson
///
/// Allows teachers to:
/// - Review all generated activities
/// - Filter by activity type
/// - Select/deselect activities
/// - Edit or delete activities
/// - Add selected activities to lesson
class ReviewActivitiesScreen extends StatefulWidget {
  final AiGenerationResponse response;
  final DocumentExtractionResult? extractedDocument;

  const ReviewActivitiesScreen({
    super.key,
    required this.response,
    this.extractedDocument,
  });

  @override
  State<ReviewActivitiesScreen> createState() => _ReviewActivitiesScreenState();
}

class _ReviewActivitiesScreenState extends State<ReviewActivitiesScreen> {
  // Copy of activities from response (can be modified)
  late List<ActivityModel> _activities;

  // Selection state for each activity
  late List<bool> _selectedActivities;

  // Current filter type
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();

    // Copy activities from response
    _activities = List.from(widget.response.activities);

    // Initialize all as selected
    _selectedActivities = List.filled(_activities.length, true);
  }

  /// Returns filtered activities based on current filter
  List<ActivityModel> _getFilteredActivities() {
    if (_filterType == 'all') {
      return _activities;
    }
    return _activities.where((activity) => activity.type == _filterType).toList();
  }

  /// Returns count of selected activities
  int _getSelectedCount() {
    return _selectedActivities.where((selected) => selected).length;
  }

  /// Toggles selection for activity at index
  void _toggleSelection(int index) {
    setState(() {
      _selectedActivities[index] = !_selectedActivities[index];
    });
  }

  /// Toggles all selections (select all / deselect all)
  void _toggleAllSelections() {
    final allSelected = _selectedActivities.every((selected) => selected);

    setState(() {
      if (allSelected) {
        // Deselect all
        _selectedActivities = List.filled(_activities.length, false);
      } else {
        // Select all
        _selectedActivities = List.filled(_activities.length, true);
      }
    });
  }

  /// Deletes selected activities
  void _onDeleteSelected() {
    // Check if any activities are selected
    if (_getSelectedCount() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select activities to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activities'),
        content: Text(
          'Are you sure you want to delete ${_getSelectedCount()} selected activities?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove selected activities
              setState(() {
                for (int i = _activities.length - 1; i >= 0; i--) {
                  if (_selectedActivities[i]) {
                    _activities.removeAt(i);
                    _selectedActivities.removeAt(i);
                  }
                }
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected activities deleted'),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Edits an activity at the given index
  Future<void> _editActivity(int index) async {
    final activity = _activities[index];

    // Show different edit dialog based on activity type
    ActivityModel? editedActivity;

    switch (activity.type) {
      case 'multiple_choice':
        editedActivity = await _showEditMultipleChoiceDialog(activity);
        break;
      case 'fill_blank':
        editedActivity = await _showEditFillBlankDialog(activity);
        break;
      case 'true_false':
        editedActivity = await _showEditTrueFalseDialog(activity);
        break;
      case 'drag_drop':
        editedActivity = await _showEditDragDropDialog(activity);
        break;
    }

    // Update activity if edited
    if (editedActivity != null) {
      setState(() {
        _activities[index] = editedActivity!;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Shows edit dialog for multiple choice activity
  Future<ActivityModel?> _showEditMultipleChoiceDialog(ActivityModel activity) async {
    final questionController = TextEditingController(text: activity.question);
    final option1Controller = TextEditingController(text: activity.options?[0]);
    final option2Controller = TextEditingController(text: activity.options?[1]);
    final option3Controller = TextEditingController(text: activity.options?[2]);
    final option4Controller = TextEditingController(text: activity.options?[3]);
    final pointsController = TextEditingController(text: activity.points.toString());

    // Determine if this is single or multiple answer mode
    bool isMultipleAnswers = activity.correctAnswerIndices != null && activity.correctAnswerIndices!.isNotEmpty;

    // Initialize selection state
    int correctAnswerIndex = activity.correctAnswerIndex ?? 0;
    Set<int> selectedAnswers = activity.correctAnswerIndices != null
        ? Set<int>.from(activity.correctAnswerIndices!)
        : {};

    return showDialog<ActivityModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Multiple Choice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Toggle for single vs multiple answers
                SwitchListTile(
                  title: const Text('Multiple Correct Answers'),
                  subtitle: const Text('Allow selecting more than one correct answer'),
                  value: isMultipleAnswers,
                  onChanged: (value) {
                    setState(() {
                      isMultipleAnswers = value;
                      if (isMultipleAnswers && selectedAnswers.isEmpty) {
                        // Initialize with current single answer
                        selectedAnswers = {correctAnswerIndex};
                      } else if (!isMultipleAnswers && selectedAnswers.isNotEmpty) {
                        // Use first selected answer as the single answer
                        correctAnswerIndex = selectedAnswers.first;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                ...List.generate(4, (i) {
                  final controllers = [option1Controller, option2Controller, option3Controller, option4Controller];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (isMultipleAnswers)
                          Checkbox(
                            value: selectedAnswers.contains(i),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedAnswers.add(i);
                                } else {
                                  selectedAnswers.remove(i);
                                }
                              });
                            },
                          )
                        else
                          Radio<int>(
                            value: i,
                            groupValue: correctAnswerIndex,
                            onChanged: (value) {
                              setState(() {
                                correctAnswerIndex = value!;
                              });
                            },
                          ),
                        Expanded(
                          child: TextField(
                            controller: controllers[i],
                            decoration: InputDecoration(
                              labelText: 'Option ${i + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate that at least one answer is selected
                if (isMultipleAnswers && selectedAnswers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one correct answer'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final edited = activity.copyWith(
                  question: questionController.text,
                  options: [
                    option1Controller.text,
                    option2Controller.text,
                    option3Controller.text,
                    option4Controller.text,
                  ],
                  correctAnswerIndex: isMultipleAnswers ? null : correctAnswerIndex,
                  correctAnswerIndices: isMultipleAnswers ? (selectedAnswers.toList()..sort()) : null,
                  points: int.tryParse(pointsController.text) ?? activity.points,
                );
                Navigator.pop(context, edited);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows edit dialog for fill in the blank activity
  Future<ActivityModel?> _showEditFillBlankDialog(ActivityModel activity) async {
    final questionController = TextEditingController(text: activity.question);
    final blankSentenceController = TextEditingController(
      text: activity.blankSentence ?? activity.question,
    );
    final correctWordController = TextEditingController(
      text: activity.correctWord,
    );
    final pointsController = TextEditingController(text: activity.points.toString());

    return showDialog<ActivityModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fill in the Blank'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: blankSentenceController,
                decoration: const InputDecoration(
                  labelText: 'Sentence with blank (use ___ for blank)',
                  border: OutlineInputBorder(),
                  helperText: 'Example: The cat is ___ the mat',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: correctWordController,
                decoration: const InputDecoration(
                  labelText: 'Correct Answer',
                  border: OutlineInputBorder(),
                  helperText: 'Example: on',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final edited = activity.copyWith(
                question: questionController.text,
                blankSentence: blankSentenceController.text,
                correctWord: correctWordController.text,
                points: int.tryParse(pointsController.text) ?? activity.points,
              );
              Navigator.pop(context, edited);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows edit dialog for true/false activity
  Future<ActivityModel?> _showEditTrueFalseDialog(ActivityModel activity) async {
    final questionController = TextEditingController(text: activity.question);
    final pointsController = TextEditingController(text: activity.points.toString());
    bool correctAnswer = activity.correctAnswer ?? true;

    return showDialog<ActivityModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit True/False'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Correct Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<bool>(
                  title: const Text('True'),
                  value: true,
                  groupValue: correctAnswer,
                  onChanged: (value) {
                    setState(() {
                      correctAnswer = value!;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('False'),
                  value: false,
                  groupValue: correctAnswer,
                  onChanged: (value) {
                    setState(() {
                      correctAnswer = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final edited = activity.copyWith(
                  question: questionController.text,
                  correctAnswer: correctAnswer,
                  points: int.tryParse(pointsController.text) ?? activity.points,
                );
                Navigator.pop(context, edited);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows edit dialog for drag & drop activity
  Future<ActivityModel?> _showEditDragDropDialog(ActivityModel activity) async {
    final questionController = TextEditingController(text: activity.question);
    final leftItemsController = TextEditingController(
      text: activity.leftItems?.join('\n'),
    );
    final rightItemsController = TextEditingController(
      text: activity.rightItems?.join('\n'),
    );
    final pointsController = TextEditingController(text: activity.points.toString());

    return showDialog<ActivityModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Drag & Drop'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: leftItemsController,
                decoration: const InputDecoration(
                  labelText: 'Left Items (one per line)',
                  border: OutlineInputBorder(),
                  helperText: 'Example:\nDog\nCat\nBird',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rightItemsController,
                decoration: const InputDecoration(
                  labelText: 'Right Items (one per line, matching order)',
                  border: OutlineInputBorder(),
                  helperText: 'Example:\nBarks\nMeows\nChirps',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final leftItems = leftItemsController.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final rightItems = rightItemsController.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              // Create correct pairs mapping ("0"->"0", "1"->"1", "2"->"2", etc.)
              final correctPairs = <String, String>{};
              for (int i = 0; i < leftItems.length && i < rightItems.length; i++) {
                correctPairs[i.toString()] = i.toString();
              }

              final edited = activity.copyWith(
                question: questionController.text,
                leftItems: leftItems,
                rightItems: rightItems,
                correctPairs: correctPairs,
                points: int.tryParse(pointsController.text) ?? activity.points,
              );
              Navigator.pop(context, edited);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Adds selected activities to lesson
  void _onAddToLesson() {
    // Get selected activities
    final selectedActivities = <ActivityModel>[];
    for (int i = 0; i < _activities.length; i++) {
      if (_selectedActivities[i]) {
        selectedActivities.add(_activities[i]);
      }
    }

    // Check if any activities are selected
    if (selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one activity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Return selected activities AND document info to previous screen
    Navigator.pop(context, {
      'activities': selectedActivities,
      'vocabulary': widget.response.vocabulary,
      'extractedDocument': widget.extractedDocument,
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedActivities.length} activities added to lesson'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Save selected activities as a standalone lesson
  Future<void> _onSaveAsLesson() async {
    // Get selected activities
    final selectedActivities = <ActivityModel>[];
    for (int i = 0; i < _activities.length; i++) {
      if (_selectedActivities[i]) {
        selectedActivities.add(_activities[i]);
      }
    }

    // Check if any activities are selected
    if (selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one activity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to collect lesson details
    await _showSaveAsLessonDialog(selectedActivities);
  }

  /// Show dialog to collect lesson details before saving
  Future<void> _showSaveAsLessonDialog(List<ActivityModel> activities) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save lessons'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Load teacher's classes
    List<ClassModel> classes = [];
    try {
      classes = await ClassService.instance.getTeacherClasses(user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading classes: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a class first before saving lessons'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Controllers for dialog
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    ClassModel? selectedClass = classes.first;
    String selectedStatus = 'draft';
    int selectedGrade = 3;
    int selectedDifficulty = 2;

    // Suggest a default title based on source text
    titleController.text = 'AI Generated Lesson';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Save as Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Lesson Title *',
                    hintText: 'Enter lesson title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Brief description of the lesson',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Class Selection
                DropdownButtonFormField<ClassModel>(
                  value: selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class *',
                    border: OutlineInputBorder(),
                  ),
                  items: classes
                      .map((classModel) => DropdownMenuItem(
                            value: classModel,
                            child: Text(classModel.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClass = value;
                      if (value != null) {
                        selectedGrade = value.grade;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Grade (auto-filled from class)
                DropdownButtonFormField<int>(
                  value: selectedGrade,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('Grade ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedGrade = value ?? 3;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Difficulty
                DropdownButtonFormField<int>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - Beginner')),
                    DropdownMenuItem(value: 2, child: Text('2 - Easy')),
                    DropdownMenuItem(value: 3, child: Text('3 - Medium')),
                    DropdownMenuItem(value: 4, child: Text('4 - Hard')),
                    DropdownMenuItem(value: 5, child: Text('5 - Expert')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDifficulty = value ?? 2;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Status (Draft or Published)
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft (not visible to students)')),
                    DropdownMenuItem(value: 'published', child: Text('Published (visible to students)')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value ?? 'draft';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Info about what will be saved
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Lesson will include:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('• ${activities.length} activities'),
                      Text('• Source text as lesson content'),
                      Text('• Total points: ${activities.fold(0, (sum, a) => sum + a.points)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a lesson title'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (selectedClass == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a class'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Store navigator before async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Close the form dialog
                navigator.pop();

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Upload document to Firebase Storage if available
                  String? documentUrl;
                  String? documentName;
                  String? documentType;

                  if (widget.extractedDocument != null &&
                      widget.extractedDocument!.originalBytes != null) {
                    print('>>> UPLOADING DOCUMENT FROM SAVE AS LESSON');

                    try {
                      final storageService = DocumentStorageService();
                      final tempLessonId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

                      documentUrl = await storageService.uploadDocument(
                        bytes: widget.extractedDocument!.originalBytes,
                        fileName: widget.extractedDocument!.fileName,
                        lessonId: tempLessonId,
                      );

                      documentName = widget.extractedDocument!.fileName;
                      documentType = widget.extractedDocument!.fileType;

                      print('>>> Document uploaded: $documentUrl');
                    } catch (uploadError) {
                      print('>>> Document upload failed: $uploadError');
                      // Continue anyway - lesson can still be saved
                    }
                  }

                  // Create lesson model
                  final lesson = LessonModel(
                    id: '', // Will be set by Firebase
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    classId: selectedClass!.id,
                    teacherId: user.uid,
                    grade: selectedGrade,
                    difficulty: selectedDifficulty,
                    topic: 'AI Generated',
                    textContent: widget.response.sourceText,
                    createdAt: DateTime.now(),
                    status: selectedStatus,
                    activities: activities,
                    sourceDocumentUrl: documentUrl,
                    sourceDocumentName: documentName,
                    sourceDocumentType: documentType,
                    sourceText: widget.extractedDocument?.text,
                    isAiGenerated: true,
                  );

                  // Save to Firebase
                  final lessonId = await LessonService.instance.createLesson(lesson);

                  // Close loading dialog
                  if (mounted) {
                    navigator.pop();

                    // Show success
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          selectedStatus == 'published'
                              ? 'Lesson published! Students can now see it.'
                              : 'Lesson saved as draft.',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );

                    // Return to previous screen (AI generator screen)
                    navigator.pop();
                  }
                } catch (e) {
                  // Close loading dialog
                  if (mounted) {
                    navigator.pop();

                    // Show error
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error saving lesson: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Lesson'),
            ),
          ],
        ),
      ),
    );
  }

  /// Gets count of activities by type
  int _getCountByType(String type) {
    return _activities.where((activity) => activity.type == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedActivities.every((selected) => selected);

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Activities (${_activities.length})'),
        actions: [
          IconButton(
            icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
            onPressed: _toggleAllSelections,
            tooltip: allSelected ? 'Deselect All' : 'Select All',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _onDeleteSelected,
            tooltip: 'Delete Selected',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          _buildSummaryCard(),

          // Filter Bar
          _buildFilterBar(),

          // Activities List
          Expanded(
            child: _buildActivitiesList(),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  /// Builds the summary card at the top
  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated ${_activities.length} activities in ${widget.response.generationTime.inSeconds}s',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_getCountByType('multiple_choice') > 0)
                  Chip(
                    label: Text('Multiple Choice: ${_getCountByType('multiple_choice')}'),
                    avatar: const Icon(Icons.radio_button_checked, size: 16),
                  ),
                if (_getCountByType('fill_blank') > 0)
                  Chip(
                    label: Text('Fill Blank: ${_getCountByType('fill_blank')}'),
                    avatar: const Icon(Icons.edit, size: 16),
                  ),
                if (_getCountByType('true_false') > 0)
                  Chip(
                    label: Text('True/False: ${_getCountByType('true_false')}'),
                    avatar: const Icon(Icons.check_circle, size: 16),
                  ),
                if (_getCountByType('drag_drop') > 0)
                  Chip(
                    label: Text('Drag & Drop: ${_getCountByType('drag_drop')}'),
                    avatar: const Icon(Icons.swap_horiz, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.response.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the filter bar
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterType == 'all',
            onSelected: (selected) {
              setState(() => _filterType = 'all');
            },
          ),
          FilterChip(
            label: const Text('Multiple Choice'),
            selected: _filterType == 'multiple_choice',
            onSelected: (selected) {
              setState(() => _filterType = 'multiple_choice');
            },
          ),
          FilterChip(
            label: const Text('Fill Blank'),
            selected: _filterType == 'fill_blank',
            onSelected: (selected) {
              setState(() => _filterType = 'fill_blank');
            },
          ),
          FilterChip(
            label: const Text('True/False'),
            selected: _filterType == 'true_false',
            onSelected: (selected) {
              setState(() => _filterType = 'true_false');
            },
          ),
          FilterChip(
            label: const Text('Drag & Drop'),
            selected: _filterType == 'drag_drop',
            onSelected: (selected) {
              setState(() => _filterType = 'drag_drop');
            },
          ),
        ],
      ),
    );
  }

  /// Builds the activities list
  Widget _buildActivitiesList() {
    final filteredActivities = _getFilteredActivities();

    if (filteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No activities match this filter',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredActivities.length,
      itemBuilder: (context, filteredIndex) {
        // Find the actual index in _activities list
        final activity = filteredActivities[filteredIndex];
        final actualIndex = _activities.indexOf(activity);

        return ActivityReviewCard(
          activity: activity,
          isSelected: _selectedActivities[actualIndex],
          index: filteredIndex,
          onToggleSelect: () => _toggleSelection(actualIndex),
          onEdit: () => _editActivity(actualIndex),
          onDelete: () {
            setState(() {
              _activities.removeAt(actualIndex);
              _selectedActivities.removeAt(actualIndex);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Activity deleted'),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the bottom action bar
  Widget _buildBottomActionBar() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                Text(
                  '${_getSelectedCount()} selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _onSaveAsLesson,
                    icon: const Icon(Icons.save),
                    label: const Text('Save as Lesson'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _onAddToLesson,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Add to Existing'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for displaying and interacting with a single activity
class ActivityReviewCard extends StatelessWidget {
  final ActivityModel activity;
  final bool isSelected;
  final int index;
  final VoidCallback onToggleSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActivityReviewCard({
    super.key,
    required this.activity,
    required this.isSelected,
    required this.index,
    required this.onToggleSelect,
    this.onEdit,
    this.onDelete,
  });

  /// Gets icon for activity type
  IconData _getIconForType(String type) {
    switch (type) {
      case 'multiple_choice':
        return Icons.radio_button_checked;
      case 'fill_blank':
        return Icons.edit;
      case 'true_false':
        return Icons.check_circle;
      case 'drag_drop':
        return Icons.swap_horiz;
      default:
        return Icons.help_outline;
    }
  }

  /// Gets color for activity type
  Color _getColorForType(String type) {
    switch (type) {
      case 'multiple_choice':
        return Colors.blue;
      case 'fill_blank':
        return Colors.orange;
      case 'true_false':
        return Colors.green;
      case 'drag_drop':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Gets display name for activity type
  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'true_false':
        return 'True/False';
      case 'drag_drop':
        return 'Drag & Drop';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          CheckboxListTile(
            value: isSelected,
            onChanged: (_) => onToggleSelect(),
            title: Row(
              children: [
                Icon(
                  _getIconForType(activity.type),
                  color: _getColorForType(activity.type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.question,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _getTypeDisplayName(activity.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getColorForType(activity.type),
                  ),
                ),
                const SizedBox(height: 8),
                _buildActivityDetails(context),
                const SizedBox(height: 4),
                Text(
                  '${activity.points} points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds activity-specific details based on type
  Widget _buildActivityDetails(BuildContext context) {
    switch (activity.type) {
      case 'multiple_choice':
        return _buildMultipleChoiceDetails(context);
      case 'fill_blank':
        return _buildFillBlankDetails(context);
      case 'true_false':
        return _buildTrueFalseDetails(context);
      case 'drag_drop':
        return _buildDragDropDetails(context);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds multiple choice activity details
  Widget _buildMultipleChoiceDetails(BuildContext context) {
    // Check if this is a multiple-answer question
    final hasMultipleAnswers = activity.correctAnswerIndices != null &&
                                activity.correctAnswerIndices!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activity.options!.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          // Determine if this option is correct
          final isCorrect = hasMultipleAnswers
              ? activity.correctAnswerIndices!.contains(index)
              : index == activity.correctAnswerIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  isCorrect
                      ? (hasMultipleAnswers ? Icons.check_box : Icons.check_circle)
                      : (hasMultipleAnswers ? Icons.check_box_outline_blank : Icons.radio_button_unchecked),
                  size: 16,
                  color: isCorrect ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCorrect ? Colors.green.shade700 : null,
                      fontWeight: isCorrect ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Builds fill in the blank activity details
  Widget _buildFillBlankDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.blankSentence ?? '',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Answer: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                activity.correctWord ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds true/false activity details
  Widget _buildTrueFalseDetails(BuildContext context) {
    final isTrue = activity.correctAnswer == true;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check : Icons.close,
            size: 20,
            color: isTrue ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            isTrue ? 'TRUE' : 'FALSE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isTrue ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds drag and drop activity details
  Widget _buildDragDropDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Matching pairs:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...activity.correctPairs!.entries.take(3).map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (activity.correctPairs!.length > 3)
            Text(
              '+ ${activity.correctPairs!.length - 3} more pairs',
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
