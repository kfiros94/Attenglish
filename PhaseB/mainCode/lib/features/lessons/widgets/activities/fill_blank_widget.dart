import 'package:flutter/material.dart';
import '../../models/activity_model.dart';

/// Widget for displaying and interacting with fill in the blank questions
class FillBlankWidget extends StatefulWidget {
  final ActivityModel activity;
  final Function(bool isCorrect, int points) onAnswered;

  const FillBlankWidget({
    super.key,
    required this.activity,
    required this.onAnswered,
  });

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  final _answerController = TextEditingController();
  bool _hasChecked = false;
  bool? _isCorrect;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an answer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _hasChecked = true;
      // Case-insensitive comparison
      _isCorrect = _answerController.text.trim().toLowerCase() ==
          widget.activity.correctWord!.toLowerCase();
    });

    // Notify parent
    widget.onAnswered(_isCorrect!, widget.activity.points);
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.activity.instructions!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sentence with blank
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.activity.blankSentence!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Answer TextField
        TextField(
          controller: _answerController,
          enabled: !_hasChecked,
          decoration: InputDecoration(
            labelText: 'Your Answer',
            hintText: 'Type the missing word',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.edit),
            filled: _hasChecked,
            fillColor: _hasChecked ? Colors.grey.shade100 : null,
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          onSubmitted: _hasChecked ? null : (_) => _checkAnswer(),
        ),

        // Feedback
        if (_hasChecked) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isCorrect! ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCorrect! ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCorrect! ? Icons.celebration : Icons.info_outline,
                  color: _isCorrect! ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCorrect! ? 'Correct!' : 'Incorrect',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect! ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isCorrect!
                            ? 'You earned ${widget.activity.points} points!'
                            : 'The correct answer is: ${widget.activity.correctWord}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isCorrect!
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Check Answer Button
        if (!_hasChecked)
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Check Answer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
