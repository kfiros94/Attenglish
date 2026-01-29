import 'package:flutter/material.dart';
import '../../models/activity_model.dart';

/// Widget for displaying and interacting with true/false questions
class TrueFalseWidget extends StatefulWidget {
  final ActivityModel activity;
  final Function(bool isCorrect, int points) onAnswered;

  const TrueFalseWidget({
    super.key,
    required this.activity,
    required this.onAnswered,
  });

  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  bool? _selectedAnswer;
  bool _hasChecked = false;
  bool? _isCorrect;

  void _checkAnswer() {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select True or False'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _hasChecked = true;
      _isCorrect = _selectedAnswer == widget.activity.correctAnswer;
    });

    // Notify parent
    widget.onAnswered(_isCorrect!, widget.activity.points);
  }

  Color _getButtonColor(bool isTrue) {
    if (!_hasChecked) {
      // Before checking: highlight selected
      if (_selectedAnswer == null) {
        return isTrue ? Colors.green.shade50 : Colors.orange.shade50;
      }
      if (_selectedAnswer == isTrue) {
        return isTrue ? Colors.green : Colors.orange;
      }
      return isTrue ? Colors.green.shade50 : Colors.orange.shade50;
    }

    // After checking
    final correctAnswer = widget.activity.correctAnswer!;
    if (correctAnswer == isTrue) {
      return isTrue ? Colors.green : Colors.orange; // Correct answer is always highlighted
    }

    if (_selectedAnswer == isTrue && !_isCorrect!) {
      return Colors.red.shade100; // Wrong selected answer is red
    }

    return isTrue ? Colors.green.shade50 : Colors.orange.shade50;
  }

  Color _getButtonBorderColor(bool isTrue) {
    if (!_hasChecked) {
      if (_selectedAnswer == isTrue) {
        return isTrue ? Colors.green.shade700 : Colors.orange.shade700;
      }
      return isTrue ? Colors.green.shade200 : Colors.orange.shade200;
    }

    // After checking
    final correctAnswer = widget.activity.correctAnswer!;
    if (correctAnswer == isTrue) {
      return isTrue ? Colors.green.shade700 : Colors.orange.shade700;
    }

    if (_selectedAnswer == isTrue && !_isCorrect!) {
      return Colors.red;
    }

    return Colors.grey.shade300;
  }

  Color _getButtonTextColor(bool isTrue) {
    if (!_hasChecked) {
      if (_selectedAnswer == isTrue) {
        return Colors.white;
      }
      return isTrue ? Colors.green.shade700 : Colors.orange.shade700;
    }

    // After checking
    final correctAnswer = widget.activity.correctAnswer!;
    if (correctAnswer == isTrue) {
      return Colors.white;
    }

    if (_selectedAnswer == isTrue && !_isCorrect!) {
      return Colors.red.shade700;
    }

    return Colors.grey.shade600;
  }

  IconData _getButtonIcon(bool isTrue) {
    if (!_hasChecked) {
      return isTrue ? Icons.check_circle : Icons.cancel;
    }

    // After checking
    final correctAnswer = widget.activity.correctAnswer!;
    if (correctAnswer == isTrue) {
      return isTrue ? Icons.check_circle : Icons.cancel;
    }

    if (_selectedAnswer == isTrue && !_isCorrect!) {
      return Icons.close;
    }

    return isTrue ? Icons.check_circle_outline : Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Statement
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.activity.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Question prompt
        const Text(
          'Is this statement true or false?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // True/False Buttons
        Row(
          children: [
            // TRUE Button
            Expanded(
              child: GestureDetector(
                onTap: _hasChecked
                    ? null
                    : () {
                        setState(() {
                          _selectedAnswer = true;
                        });
                      },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getButtonColor(true),
                    border: Border.all(
                      color: _getButtonBorderColor(true),
                      width: _selectedAnswer == true ||
                             (_hasChecked && widget.activity.correctAnswer == true)
                          ? 3
                          : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getButtonIcon(true),
                        size: 48,
                        color: _getButtonTextColor(true),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TRUE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getButtonTextColor(true),
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
                onTap: _hasChecked
                    ? null
                    : () {
                        setState(() {
                          _selectedAnswer = false;
                        });
                      },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getButtonColor(false),
                    border: Border.all(
                      color: _getButtonBorderColor(false),
                      width: _selectedAnswer == false ||
                             (_hasChecked && widget.activity.correctAnswer == false)
                          ? 3
                          : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getButtonIcon(false),
                        size: 48,
                        color: _getButtonTextColor(false),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FALSE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getButtonTextColor(false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                            : 'The correct answer is: ${widget.activity.correctAnswer! ? "TRUE" : "FALSE"}',
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
                backgroundColor: Colors.orange,
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
