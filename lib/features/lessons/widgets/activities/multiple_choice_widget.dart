import 'package:flutter/material.dart';
import '../../models/activity_model.dart';

/// Widget for displaying and interacting with multiple choice questions
class MultipleChoiceWidget extends StatefulWidget {
  final ActivityModel activity;
  final Function(bool isCorrect, int points) onAnswered;

  const MultipleChoiceWidget({
    super.key,
    required this.activity,
    required this.onAnswered,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  int? _selectedIndex;
  Set<int> _selectedIndices = {};
  bool _hasChecked = false;
  bool? _isCorrect;

  bool get _isMultipleAnswers =>
      widget.activity.correctAnswerIndices != null &&
      widget.activity.correctAnswerIndices!.isNotEmpty;

  void _checkAnswer() {
    if (_isMultipleAnswers) {
      if (_selectedIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one answer'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _hasChecked = true;
        // Check if selected answers match correct answers exactly
        final correctSet = Set<int>.from(widget.activity.correctAnswerIndices!);
        _isCorrect = _selectedIndices.length == correctSet.length &&
            _selectedIndices.every((index) => correctSet.contains(index));
      });
    } else {
      if (_selectedIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an answer'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _hasChecked = true;
        _isCorrect = _selectedIndex == widget.activity.correctAnswerIndex;
      });
    }

    // Notify parent
    widget.onAnswered(_isCorrect!, widget.activity.points);
  }

  bool _isCorrectAnswer(int index) {
    if (_isMultipleAnswers) {
      return widget.activity.correctAnswerIndices!.contains(index);
    } else {
      return index == widget.activity.correctAnswerIndex;
    }
  }

  bool _isSelected(int index) {
    if (_isMultipleAnswers) {
      return _selectedIndices.contains(index);
    } else {
      return _selectedIndex == index;
    }
  }

  Color _getOptionColor(int index) {
    if (!_hasChecked) {
      return _isSelected(index) ? Colors.blue.shade100 : Colors.white;
    }

    // After checking
    if (_isCorrectAnswer(index)) {
      return Colors.green.shade100; // Correct answer is always green
    }

    if (_isSelected(index) && !_isCorrect!) {
      return Colors.red.shade100; // Wrong selected answer is red
    }

    return Colors.grey.shade100;
  }

  IconData? _getOptionIcon(int index) {
    if (!_hasChecked) {
      if (_isMultipleAnswers) {
        return _selectedIndices.contains(index)
            ? Icons.check_box
            : Icons.check_box_outline_blank;
      } else {
        return _selectedIndex == index
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked;
      }
    }

    // After checking
    if (_isCorrectAnswer(index)) {
      return Icons.check_circle;
    }

    if (_isSelected(index) && !_isCorrect!) {
      return Icons.cancel;
    }

    return null;
  }

  Color _getOptionIconColor(int index) {
    if (!_hasChecked) {
      return _isSelected(index) ? Colors.blue : Colors.grey;
    }

    // After checking
    if (_isCorrectAnswer(index)) {
      return Colors.green;
    }

    if (_isSelected(index) && !_isCorrect!) {
      return Colors.red;
    }

    return Colors.grey;
  }

  String _getCorrectAnswerText() {
    if (_isMultipleAnswers) {
      final correctAnswers = widget.activity.correctAnswerIndices!
          .map((idx) => widget.activity.options![idx])
          .join(', ');
      return 'The correct answers are: $correctAnswers';
    } else {
      return 'The correct answer is: ${widget.activity.options![widget.activity.correctAnswerIndex!]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.activity.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Options
        ...List.generate(
          widget.activity.options?.length ?? 0,
          (index) {
            final option = widget.activity.options![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _hasChecked
                    ? null
                    : () {
                        setState(() {
                          if (_isMultipleAnswers) {
                            // Toggle selection for multiple answers
                            if (_selectedIndices.contains(index)) {
                              _selectedIndices.remove(index);
                            } else {
                              _selectedIndices.add(index);
                            }
                          } else {
                            // Single answer selection
                            _selectedIndex = index;
                          }
                        });
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getOptionColor(index),
                    border: Border.all(
                      color: _isSelected(index)
                          ? Colors.blue
                          : Colors.grey.shade300,
                      width: _isSelected(index) ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getOptionIcon(index),
                        color: _getOptionIconColor(index),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
                            : _getCorrectAnswerText(),
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
                backgroundColor: Colors.blue,
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
