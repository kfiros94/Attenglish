import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Help button widget that shows a menu with help options
class HelpButton extends StatelessWidget {
  final VoidCallback onReplayTutorial;
  final VoidCallback? onShowHelp;
  final double size;

  const HelpButton({
    super.key,
    required this.onReplayTutorial,
    this.onShowHelp,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    return PopupMenuButton<String>(
      icon: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.help_outline,
          color: AppColors.primary,
          size: size * 0.55,
        ),
      ),
      tooltip: isRTL ? 'עזרה' : 'Help',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      offset: const Offset(0, 8),
      onSelected: (value) {
        switch (value) {
          case 'tutorial':
            onReplayTutorial();
            break;
          case 'help':
            onShowHelp?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'tutorial',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRTL ? 'הדרכה' : 'Tutorial',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isRTL ? 'הפעל שוב את ההדרכה' : 'Replay the guided tour',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onShowHelp != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'help',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRTL ? 'עזרה' : 'Help Topics',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isRTL ? 'קרא על כל התכונות' : 'Learn about all features',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple circular help button (? icon)
class SimpleHelpButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final Color? color;

  const SimpleHelpButton({
    super.key,
    required this.onTap,
    this.size = 36,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;
    final buttonColor = color ?? AppColors.primary;

    return Tooltip(
      message: isRTL ? 'עזרה והדרכה' : 'Help & Tutorial',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: buttonColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                color: buttonColor,
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Help dialog showing quick help topics
class HelpDialog extends StatelessWidget {
  final String userRole;

  const HelpDialog({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;
    final isStudent = userRole.toLowerCase() == 'student';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isRTL ? 'במה אוכל לעזור?' : 'What do you need help with?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Help topics
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: isStudent
                      ? _buildStudentHelpTopics(context, isRTL)
                      : _buildTeacherHelpTopics(context, isRTL),
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isRTL ? 'סגור' : 'Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentHelpTopics(BuildContext context, bool isRTL) {
    return [
      _buildHelpTopic(
        context,
        icon: Icons.school,
        title: isRTL ? 'איך להתחיל שיעור' : 'Starting a Lesson',
        description: isRTL
            ? 'לחץ על כרטיס שיעור כדי לפתוח אותו. השלם את כל הפעילויות כדי לסיים.'
            : 'Tap a lesson card to open it. Complete all activities to finish.',
      ),
      _buildHelpTopic(
        context,
        icon: Icons.edit_note,
        title: isRTL ? 'ביצוע פעילויות' : 'Doing Activities',
        description: isRTL
            ? 'קרא את ההוראות. ענה כשאתה מוכן. קח את הזמן שלך!'
            : 'Read the instructions. Answer when ready. Take your time!',
      ),
      _buildHelpTopic(
        context,
        icon: Icons.stars,
        title: isRTL ? 'צבירת נקודות' : 'Earning Points',
        description: isRTL
            ? 'תקבל XP על כל פעילות. ככל שתשיג יותר, תצבור יותר נקודות!'
            : 'You get XP for each activity. Better scores = more points!',
      ),
    ];
  }

  List<Widget> _buildTeacherHelpTopics(BuildContext context, bool isRTL) {
    return [
      _buildHelpTopic(
        context,
        icon: Icons.edit_note,
        title: isRTL ? 'יצירת שיעורים' : 'Creating Lessons',
        description: isRTL
            ? 'הוסף כותרת, תוכן ופעילויות. שמור כטיוטה או פרסם.'
            : 'Add title, content, and activities. Save as draft or publish.',
      ),
      _buildHelpTopic(
        context,
        icon: Icons.auto_awesome,
        title: isRTL ? 'שימוש במחולל AI' : 'Using AI Generator',
        description: isRTL
            ? 'בחר סוג פעילות ותאר את הנושא. ה-AI יצור פעילויות בשבילך.'
            : 'Pick activity type and describe the topic. AI creates activities for you.',
      ),
      _buildHelpTopic(
        context,
        icon: Icons.school,
        title: isRTL ? 'ניהול כיתות' : 'Managing Classrooms',
        description: isRTL
            ? 'צור כיתות, הוסף תלמידים, והקצה להם שיעורים.'
            : 'Create classes, add students, and assign lessons to them.',
      ),
      _buildHelpTopic(
        context,
        icon: Icons.analytics,
        title: isRTL ? 'צפייה בהתקדמות' : 'Viewing Progress',
        description: isRTL
            ? 'ראה גרפים של ציונים והשלמות. זהה תלמידים שצריכים עזרה.'
            : 'See charts of scores and completions. Find students who need help.',
      ),
    ];
  }

  Widget _buildHelpTopic(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
