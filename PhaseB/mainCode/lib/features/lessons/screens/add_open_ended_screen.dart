import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Screen for teachers to create an Open-ended question activity
class AddOpenEndedScreen extends StatefulWidget {
  const AddOpenEndedScreen({super.key});

  @override
  State<AddOpenEndedScreen> createState() => _AddOpenEndedScreenState();
}

class _AddOpenEndedScreenState extends State<AddOpenEndedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storyController = TextEditingController();
  final _questionController = TextEditingController();
  final _sampleAnswerController = TextEditingController();
  final _instructionsController = TextEditingController();

  int _points = 15;

  @override
  void dispose() {
    _storyController.dispose();
    _questionController.dispose();
    _sampleAnswerController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _createActivity() {
    if (!_formKey.currentState!.validate()) return;

    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'open_ended',
      question: _questionController.text.trim(),
      storyContext: _storyController.text.trim(),
      sampleAnswer: _sampleAnswerController.text.trim().isNotEmpty
          ? _sampleAnswerController.text.trim()
          : null,
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
        title: Text(isRTL ? 'שאלה פתוחה' : 'Add Open-ended Question'),
        backgroundColor: Colors.deepPurple,
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
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.deepPurple),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: Text(
                          isRTL
                              ? 'שאלות פתוחות בודקות הבנת הנקרא. התלמיד עונה במילים שלו והבינה המלאכותית מעריכה את התשובה לפי הבנת הסיפור.'
                              : 'Open-ended questions test reading comprehension. The student answers in their own words and AI evaluates based on story understanding.',
                          style: const TextStyle(
                            color: Colors.deepPurple,
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
                maxLines: 10,
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
                  if (value.trim().length < 100) {
                    return isRTL
                        ? 'הסיפור קצר מדי (לפחות 100 תווים)'
                        : 'Story is too short (at least 100 characters)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Question input
              Text(
                isRTL ? 'השאלה *' : 'Question *',
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
                      ? 'לדוגמה: מה למדנו מהסיפור על חברות?'
                      : 'Example: What did we learn from the story about friendship?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRTL ? 'נא להזין שאלה' : 'Please enter a question';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Sample answer (optional - for AI reference)
              Text(
                isRTL ? 'תשובה לדוגמה (אופציונלי)' : 'Sample Answer (optional)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _sampleAnswerController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isRTL
                      ? 'תשובה לדוגמה שתעזור לבינה המלאכותית להעריך...'
                      : 'A sample answer to help AI evaluate responses...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  helperText: isRTL
                      ? 'עוזר לבינה המלאכותית להבין מה נחשב תשובה טובה'
                      : 'Helps AI understand what a good answer looks like',
                ),
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
                      ? 'לדוגמה: ענה ב-2-3 משפטים...'
                      : 'Example: Answer in 2-3 sentences...',
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
                min: 10,
                max: 30,
                divisions: 4,
                label: '$_points',
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    _points = value.round();
                  });
                },
              ),

              const SizedBox(height: AppTheme.spacingSmall),

              // Scoring info
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRTL ? 'הערכת הבינה המלאכותית:' : 'AI Evaluation Criteria:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRTL
                            ? '• הבנת הסיפור\n• רלוונטיות לשאלה\n• בהירות הביטוי\n• שימוש בפרטים מהסיפור'
                            : '• Story comprehension\n• Relevance to question\n• Clarity of expression\n• Use of story details',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  backgroundColor: Colors.deepPurple,
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
