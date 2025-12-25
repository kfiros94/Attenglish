import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/activity_model.dart';
import '../../../ai_generation/services/claude_ai_service.dart';

/// Widget for displaying and interacting with image description activities
/// Students view images and write descriptions
/// Claude AI evaluates the descriptions
class ImageDescriptionWidget extends StatefulWidget {
  final ActivityModel activity;
  final Function(bool isCorrect, int points) onAnswered;

  const ImageDescriptionWidget({
    super.key,
    required this.activity,
    required this.onAnswered,
  });

  @override
  State<ImageDescriptionWidget> createState() => _ImageDescriptionWidgetState();
}

class _ImageDescriptionWidgetState extends State<ImageDescriptionWidget> {
  final _descriptionController = TextEditingController();
  bool _hasChecked = false;
  bool _isEvaluating = false;
  Map<String, dynamic>? _evaluation;
  int _earnedPoints = 0;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Submit description for AI evaluation
  Future<void> _submitDescription() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isEvaluating = true;
    });

    try {
      // Call Claude AI to evaluate the description
      final evaluation = await _evaluateDescription(
        widget.activity.imageUrls!,
        _descriptionController.text.trim(),
        widget.activity.sampleAnswer,
      );

      setState(() {
        _hasChecked = true;
        _isEvaluating = false;
        _evaluation = evaluation;
        _earnedPoints = evaluation['points'] as int;
      });

      // Notify parent
      widget.onAnswered(true, _earnedPoints);
    } catch (e) {
      setState(() {
        _isEvaluating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error evaluating description: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Call Claude AI API to evaluate student's description
  Future<Map<String, dynamic>> _evaluateDescription(
    List<String> imageUrls,
    String studentDescription,
    String? sampleAnswer,
  ) async {
    final claudeService = ClaudeAiService.withDefaultKey();

    try {
      // Build evaluation prompt
      final prompt = _buildEvaluationPrompt(studentDescription, sampleAnswer);

      // Call Claude Vision API for real evaluation
      final evaluation = await claudeService.evaluateImageDescription(
        imageUrls: imageUrls,
        studentDescription: studentDescription,
        evaluationPrompt: prompt,
        maxPoints: widget.activity.points,
      );

      return evaluation;
    } finally {
      claudeService.dispose();
    }
  }

  /// Build prompt for Claude AI evaluation
  String _buildEvaluationPrompt(String studentDescription, String? sampleAnswer) {
    return '''
You are an English teacher evaluating a student's image description.

TASK: Evaluate the student's description of the image(s).

STUDENT'S DESCRIPTION:
$studentDescription

${sampleAnswer != null ? '''
SAMPLE ANSWER (for reference):
$sampleAnswer
''' : ''}

EVALUATION CRITERIA:
1. Accuracy: Does the description match what's in the image?
2. Grammar: Are there grammar mistakes?
3. Vocabulary: Is the vocabulary appropriate and varied?
4. Completeness: Did they mention key elements?

SCORING:
- Award 0-${widget.activity.points} points based on quality
- Full points: Accurate, grammatically correct, good vocabulary
- Partial points: Minor errors or missing details
- Low points: Major inaccuracies or many grammar errors

OUTPUT FORMAT (JSON):
{
  "points": <number 0-${widget.activity.points}>,
  "feedback": "<encouraging overall feedback>",
  "accuracy": "<comment on accuracy>",
  "grammar": "<comment on grammar, list specific errors>",
  "vocabulary": "<comment on vocabulary>",
  "suggestions": "<specific suggestions for improvement>"
}

IMPORTANT:
- Be encouraging and constructive
- Point out specific errors with corrections
- Mention what they did well
- Keep language simple and clear (ADHD-friendly)
''';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions (if provided)
        if (widget.activity.instructions != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.activity.instructions!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Images Display
        ...widget.activity.imageUrls!.asMap().entries.map((entry) {
          final index = entry.key;
          final imageUrl = entry.value;

          return Column(
            children: [
              if (widget.activity.imageUrls!.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Image ${index + 1} of ${widget.activity.imageUrls!.length}',
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 400,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 300,
                      color: Colors.grey.shade200,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),

        // Description TextField
        TextField(
          controller: _descriptionController,
          enabled: !_hasChecked,
          decoration: InputDecoration(
            labelText: 'Your Description',
            hintText: 'Describe what you see in the image(s)...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.edit),
            filled: _hasChecked,
            fillColor: _hasChecked ? Colors.grey.shade100 : null,
            helperText: _hasChecked ? null : 'Write at least 2-3 sentences',
          ),
          maxLines: 6,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 16),

        // Submit Button
        if (!_hasChecked)
          ElevatedButton.icon(
            onPressed: _isEvaluating ? null : _submitDescription,
            icon: _isEvaluating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isEvaluating ? 'Evaluating...' : 'Submit Description'),
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

        // Evaluation Feedback
        if (_hasChecked && _evaluation != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade300, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points Earned
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$_earnedPoints / ${widget.activity.points} points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Overall Feedback
                _buildFeedbackSection(
                  icon: Icons.celebration,
                  title: 'Feedback',
                  content: _evaluation!['feedback'] as String,
                  color: Colors.purple,
                ),
                const SizedBox(height: 12),

                // Accuracy
                _buildFeedbackSection(
                  icon: Icons.check_circle_outline,
                  title: 'Accuracy',
                  content: _evaluation!['accuracy'] as String,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),

                // Grammar
                _buildFeedbackSection(
                  icon: Icons.spellcheck,
                  title: 'Grammar',
                  content: _evaluation!['grammar'] as String,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),

                // Vocabulary
                _buildFeedbackSection(
                  icon: Icons.menu_book,
                  title: 'Vocabulary',
                  content: _evaluation!['vocabulary'] as String,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),

                // Suggestions
                _buildFeedbackSection(
                  icon: Icons.lightbulb_outline,
                  title: 'Suggestions',
                  content: _evaluation!['suggestions'] as String,
                  color: Colors.amber.shade700,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeedbackSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
