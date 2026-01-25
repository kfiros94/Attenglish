import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import 'multiple_choice_widget.dart';
import 'fill_blank_widget.dart';
import 'true_false_widget.dart';
import 'image_description_widget.dart';
import 'drag_drop_widget.dart';
import 'cloze_widget.dart';
import 'open_ended_widget.dart';

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
      case 'image_description':
        return ImageDescriptionWidget(
          activity: activity,
          onAnswered: onAnswered,
        );
      case 'drag_drop':
        return DragDropWidget(
          activity: activity,
          onAnswered: onAnswered,
        );
      case 'cloze':
        return ClozeWidget(
          activity: activity,
          onAnswered: onAnswered,
        );
      case 'open_ended':
        return OpenEndedWidget(
          activity: activity,
          onAnswered: onAnswered,
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
