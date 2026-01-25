import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Screen for teachers to create a Cloze (fill-in-the-blank from story) activity
class AddClozeScreen extends StatefulWidget {
  const AddClozeScreen({super.key});

  @override
  State<AddClozeScreen> createState() => _AddClozeScreenState();
}

class _AddClozeScreenState extends State<AddClozeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storyController = TextEditingController();
  final _questionController = TextEditingController();
  final _expectedAnswerController = TextEditingController();
  final _instructionsController = TextEditingController();

  int _points = 10;

  @override
  void dispose() {
    _storyController.dispose();
    _questionController.dispose();
    _expectedAnswerController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _createActivity() {
    if (!_formKey.currentState!.validate()) return;

    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'cloze',
      question: _questionController.text.trim(),
      storyContext: _storyController.text.trim(),
      expectedAnswer: _expectedAnswerController.text.trim(),
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      aiEvaluated: true,
      points: _points,
    );

    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRTL ? 'שאלת השלמה מסיפור' : 'Add Cloze Question'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.indigo),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: Text(
                          isRTL
                              ? 'שאלות השלמה מבוססות על סיפור. התלמיד קורא את הסיפור וממלא את המילה החסרה. הבינה המלאכותית תעריך את התשובה.'
                              : 'Cloze questions are based on a story. The student reads the story and fills in the missing word. AI will evaluate the answer.',
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: AppTheme.fontSizeSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Story/Passage input
              Text(
                isRTL ? 'הסיפור / הקטע *' : 'Story / Passage *',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _storyController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: isRTL
                      ? 'הכנס את הסיפור או הקטע שהשאלה מבוססת עליו...'
                      : 'Enter the story or passage the question is based on...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRTL ? 'נא להזין סיפור' : 'Please enter a story';
                  }
                  if (value.trim().length < 50) {
                    return isRTL
                        ? 'הסיפור קצר מדי (לפחות 50 תווים)'
                        : 'Story is too short (at least 50 characters)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Question input
              Text(
                isRTL ? 'השאלה (עם _____ במקום המילה החסרה) *' : 'Question (with _____ for the blank) *',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isRTL
                      ? 'לדוגמה: הילד הלך ל_____ לקנות לחם.'
                      : 'Example: The boy went to the _____ to buy bread.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRTL ? 'נא להזין שאלה' : 'Please enter a question';
                  }
                  if (!value.contains('_____') && !value.contains('____') && !value.contains('___')) {
                    return isRTL
                        ? 'השאלה חייבת להכיל _____ במקום המילה החסרה'
                        : 'Question must contain _____ for the blank';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Expected answer input
              Text(
                isRTL ? 'התשובה הצפויה *' : 'Expected Answer *',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _expectedAnswerController,
                decoration: InputDecoration(
                  hintText: isRTL
                      ? 'המילה הנכונה (ניתן להפריד מספר תשובות אפשריות בפסיק)'
                      : 'The correct word (separate multiple answers with comma)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRTL
                        ? 'נא להזין תשובה צפויה'
                        : 'Please enter expected answer';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Instructions (optional)
              Text(
                isRTL ? 'הוראות (אופציונלי)' : 'Instructions (optional)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _instructionsController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: isRTL
                      ? 'הוראות נוספות לתלמיד...'
                      : 'Additional instructions for the student...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Points slider
              Text(
                isRTL ? 'נקודות: $_points' : 'Points: $_points',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
              Slider(
                value: _points.toDouble(),
                min: 5,
                max: 25,
                divisions: 4,
                label: '$_points',
                activeColor: Colors.indigo,
                onChanged: (value) {
                  setState(() {
                    _points = value.round();
                  });
                },
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Create button
              ElevatedButton.icon(
                onPressed: _createActivity,
                icon: const Icon(Icons.add),
                label: Text(
                  isRTL ? 'צור פעילות' : 'Create Activity',
                  style: const TextStyle(fontSize: AppTheme.fontSizeMedium),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
