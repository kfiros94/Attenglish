import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import '../../../ai_generation/services/claude_ai_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/localization_service.dart';

/// Widget for Cloze (fill-in-the-blank from story) questions
/// AI evaluates the answer based on story context
class ClozeWidget extends StatefulWidget {
  final ActivityModel activity;
  final Function(bool isCorrect, int points) onAnswered;

  const ClozeWidget({
    super.key,
    required this.activity,
    required this.onAnswered,
  });

  @override
  State<ClozeWidget> createState() => _ClozeWidgetState();
}

class _ClozeWidgetState extends State<ClozeWidget> {
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  Map<String, dynamic>? _evaluation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Listen to text changes to enable/disable submit button
    _answerController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Trigger rebuild to update submit button state
    setState(() {});
  }

  @override
  void dispose() {
    _answerController.removeListener(_onTextChanged);
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final claudeService = ClaudeAiService.withDefaultKey();

      final evaluation = await claudeService.evaluateTextAnswer(
        storyContext: widget.activity.storyContext ?? '',
        question: widget.activity.question,
        studentAnswer: answer,
        activityType: 'cloze',
        maxPoints: widget.activity.points,
        correctAnswer: widget.activity.expectedAnswer,
      );

      setState(() {
        _evaluation = evaluation;
        _hasSubmitted = true;
        _isSubmitting = false;
      });

      // Call the callback with results
      widget.onAnswered(
        evaluation['isCorrect'] as bool,
        evaluation['points'] as int,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Activity type badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book, size: 16, color: Colors.indigo),
                const SizedBox(width: 4),
                Text(
                  isRTL ? 'שאלת השלמה מסיפור' : 'Cloze Question',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Story context (collapsible)
          if (widget.activity.storyContext != null &&
              widget.activity.storyContext!.isNotEmpty)
            _buildStorySection(isRTL),

          const SizedBox(height: AppTheme.spacingMedium),

          // Question card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.indigo,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: Text(
                          isRTL ? 'השאלה' : 'Question',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Points badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          '${widget.activity.points} ${isRTL ? "נק'" : 'pts'}',
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    widget.activity.question,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Instructions if any
                  if (widget.activity.instructions != null) ...[
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      widget.activity.instructions!,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMedium),

          // Answer input
          if (!_hasSubmitted) ...[
            TextField(
              controller: _answerController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: isRTL ? 'התשובה שלך' : 'Your Answer',
                hintText: isRTL ? 'הקלד את התשובה...' : 'Type your answer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitAnswer(),
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            // Submit button
            ElevatedButton.icon(
              onPressed: _isSubmitting ||
                      _answerController.text.trim().isEmpty
                  ? null
                  : _submitAnswer,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _isSubmitting
                    ? (isRTL ? 'בודק...' : 'Checking...')
                    : (isRTL ? 'שלח תשובה' : 'Submit Answer'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingMedium,
                ),
                backgroundColor: AppColors.primary,
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: AppTheme.fontSizeSmall,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],

          // Evaluation results
          if (_hasSubmitted && _evaluation != null) _buildEvaluationResults(isRTL),
        ],
      ),
    );
  }

  Widget _buildStorySection(bool isRTL) {
    return ExpansionTile(
      title: Row(
        children: [
          const Icon(Icons.auto_stories, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(
            isRTL ? 'הסיפור' : 'The Story',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
      initiallyExpanded: true,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            widget.activity.storyContext!,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationResults(bool isRTL) {
    final isCorrect = _evaluation!['isCorrect'] as bool;
    final points = _evaluation!['points'] as int;
    final feedback = _evaluation!['feedback'] as String;
    final explanation = _evaluation!['explanation'] as String;
    final suggestions = _evaluation!['suggestions'] as String;

    return Column(
      children: [
        const SizedBox(height: AppTheme.spacingMedium),

        // Score card
        Card(
          color: isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(
              color: isCorrect ? Colors.green : Colors.orange,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              children: [
                // Result icon and score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.info,
                      color: isCorrect ? Colors.green : Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrect
                              ? (isRTL ? 'נכון!' : 'Correct!')
                              : (isRTL ? 'כמעט!' : 'Almost!'),
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(
                          '$points / ${widget.activity.points} ${isRTL ? "נקודות" : "points"}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: isCorrect
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: AppTheme.spacingLarge),

                // Feedback
                _buildFeedbackSection(
                  icon: Icons.lightbulb,
                  title: isRTL ? 'משוב' : 'Feedback',
                  content: feedback,
                  color: Colors.blue,
                ),

                const SizedBox(height: AppTheme.spacingSmall),

                // Explanation
                _buildFeedbackSection(
                  icon: Icons.school,
                  title: isRTL ? 'הסבר' : 'Explanation',
                  content: explanation,
                  color: Colors.purple,
                ),

                const SizedBox(height: AppTheme.spacingSmall),

                // Suggestions
                _buildFeedbackSection(
                  icon: Icons.tips_and_updates,
                  title: isRTL ? 'טיפ לשיפור' : 'Tip',
                  content: suggestions,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: AppTheme.fontSizeSmall,
                ),
              ),
              Text(
                content,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
