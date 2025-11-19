import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../widgets/activities/multiple_choice_widget.dart';
import '../widgets/activities/fill_blank_widget.dart';
import '../widgets/activities/true_false_widget.dart';
import '../widgets/activities/drag_drop_widget.dart';

/// Activity Player Screen for Students
///
/// Shows activities one at a time with progress tracking.
/// Students complete each activity and see their score build up.
class StudentActivityPlayerScreen extends StatefulWidget {
  final List<ActivityModel> activities;
  final String lessonTitle;

  const StudentActivityPlayerScreen({
    super.key,
    required this.activities,
    required this.lessonTitle,
  });

  @override
  State<StudentActivityPlayerScreen> createState() =>
      _StudentActivityPlayerScreenState();
}

class _StudentActivityPlayerScreenState
    extends State<StudentActivityPlayerScreen> {
  int _currentActivityIndex = 0;
  int _totalScore = 0;
  late List<bool> _completedActivities;

  @override
  void initState() {
    super.initState();
    _completedActivities = List.filled(widget.activities.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_totalScore pts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentActivityIndex + 1) / widget.activities.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),

          // Progress text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity ${_currentActivityIndex + 1} of ${widget.activities.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_totalScore points',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Current activity widget
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildCurrentActivity(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentActivity() {
    final activity = widget.activities[_currentActivityIndex];

    switch (activity.type) {
      case 'multiple_choice':
        return MultipleChoiceWidget(
          key: ValueKey('mc_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'fill_blank':
        return FillBlankWidget(
          key: ValueKey('fb_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'true_false':
        return TrueFalseWidget(
          key: ValueKey('tf_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'drag_drop':
        return DragDropWidget(
          key: ValueKey('dd_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Unknown activity type: ${activity.type}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        );
    }
  }

  void _onActivityAnswered(bool isCorrect, int points) {
    setState(() {
      // Mark as completed
      _completedActivities[_currentActivityIndex] = true;

      // Add points only if correct
      if (isCorrect) {
        _totalScore += points;
      }

      // Check if last activity
      if (_currentActivityIndex >= widget.activities.length - 1) {
        // Show completion dialog
        _showCompletionDialog();
      } else {
        // Move to next activity after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _currentActivityIndex++;
            });
          }
        });
      }
    });
  }

  void _onBackPressed() {
    // If activities are not completed, show confirmation
    if (_completedActivities.any((completed) => !completed)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave Activity?'),
          content: const Text(
            'You haven\'t completed all activities yet. Your progress will be lost. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context, _totalScore);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber.shade700, size: 32),
            const SizedBox(width: 8),
            const Text('Great Job!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              'You completed all activities!',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Score',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalScore',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Activities: ${widget.activities.length}/${widget.activities.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, _totalScore); // Return to lesson list with score
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
