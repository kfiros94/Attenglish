import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import 'multiple_choice_widget.dart';
import 'fill_blank_widget.dart';
import 'true_false_widget.dart';

/// Wrapper widget that displays the correct activity widget based on type
class ActivityWidget extends StatelessWidget {
  final ActivityModel activity;
  final Function(bool isCorrect, int points) onAnswered;

  const ActivityWidget({
    super.key,
    required this.activity,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    switch (activity.type) {
      case 'multiple_choice':
        return MultipleChoiceWidget(
          activity: activity,
          onAnswered: onAnswered,
        );
      case 'fill_blank':
        return FillBlankWidget(
          activity: activity,
          onAnswered: onAnswered,
        );
      case 'true_false':
        return TrueFalseWidget(
          activity: activity,
          onAnswered: onAnswered,
        );
      case 'drag_drop':
        // TODO: Implement drag and drop widget
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Drag & Drop activities\ncoming soon!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Unknown activity type: ${activity.type}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }
}
