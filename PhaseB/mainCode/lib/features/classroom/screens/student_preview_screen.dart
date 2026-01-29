import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';
import '../../lessons/models/lesson_model.dart';
import '../../lessons/services/lesson_service.dart';
import '../../lessons/screens/student_lesson_viewer.dart';
import '../../lessons/widgets/mission_card.dart';
import '../../gamification/widgets/streak_calendar.dart';
import '../../classroom/widgets/classroom_info_widget.dart';
import '../../../shared/widgets/atti_mascot.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../core/theme/adhd_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/greeting_helper.dart';

/// Screen for teachers to preview the app as a specific student would see it
/// This allows teachers to test the student experience without logging out
class StudentPreviewScreen extends StatefulWidget {
  final UserModel student;

  const StudentPreviewScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentPreviewScreen> createState() => _StudentPreviewScreenState();
}

class _StudentPreviewScreenState extends State<StudentPreviewScreen> {
  Locale _currentLocale = LocalizationService.instance.currentLocale;

  @override
  void initState() {
    super.initState();

    // Listen to locale changes
    LocalizationService.instance.localeStream.listen((locale) {
      if (mounted) {
        setState(() {
          _currentLocale = locale;
        });
      }
    });
  }

  /// Get icon based on lesson topic
  String _getLessonIcon(String? topic) {
    switch (topic?.toLowerCase()) {
      case 'vocabulary':
        return '📖';
      case 'grammar':
        return '📝';
      case 'reading':
        return '📚';
      case 'writing':
        return '✍️';
      case 'listening':
        return '👂';
      case 'speaking':
        return '🗣️';
      default:
        return '📚';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    return Scaffold(
      backgroundColor: ADHDTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Teacher preview banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ADHDTheme.spacingMedium,
                vertical: ADHDTheme.spacingSmall,
              ),
              color: AppColors.secondary,
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRTL
                          ? 'צפייה כתלמיד: ${widget.student.fullName}'
                          : 'Viewing as: ${widget.student.fullName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      isRTL ? 'יציאה' : 'Exit Preview',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Student view content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
                child: _buildStudentView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentView() {
    final isRTL = LocalizationService.instance.isRTL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Large Atti mascot with greeting
        Center(
          child: AttiMascot(
            message: GreetingHelper.getMascotMessage(
              _currentLocale,
              widget.student.userName,
            ),
            size: AttiSize.large,
            showSpeechBubble: true,
          ),
        ),
        const SizedBox(height: ADHDTheme.spacingXLarge),

        // 2. Progress bar section (shows student's actual progress)
        _buildStudentProgressBar(),
        const SizedBox(height: ADHDTheme.spacingXLarge),

        // 3. Streak Calendar (shows student's activity)
        _buildStreakCalendar(),
        const SizedBox(height: ADHDTheme.spacingXLarge),

        // 4. Classroom info
        if (widget.student.classId != null) ...[
          _buildClassroomInfo(),
          const SizedBox(height: ADHDTheme.spacingXLarge),
        ],

        // 5. Today's Mission section header
        Row(
          children: [
            const Text(
              '🎯',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(width: ADHDTheme.spacingSmall),
            Text(
              AppStrings.todaysMission(_currentLocale),
              style: ADHDTheme.studentTextTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ADHDTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: ADHDTheme.spacingMedium),

        // 6. Mission cards (student's lessons)
        if (widget.student.classId != null)
          _buildLessonsSection()
        else
          _buildNoClassMessage(),
      ],
    );
  }

  Widget _buildStudentProgressBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.student.id)
          .snapshots(),
      builder: (context, snapshot) {
        int xpPoints = widget.student.xpPoints;
        int currentLevel = widget.student.currentLevel;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          xpPoints = userData['xpPoints'] ?? xpPoints;
          currentLevel = userData['currentLevel'] ?? currentLevel;
        }

        // Calculate progress within current level
        final xpForNextLevel = currentLevel * 100;
        final progress = (xpPoints % 100) / 100;

        return Container(
          padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $currentLevel',
                    style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ADHDTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    '$xpPoints XP',
                    style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ADHDTheme.accentOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ADHDTheme.spacingSmall),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: ADHDTheme.primaryBlue.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    ADHDTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}% to Level ${currentLevel + 1}',
                style: ADHDTheme.studentTextTheme.bodySmall?.copyWith(
                  color: ADHDTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCalendar() {
    // Show a simplified streak view for the student
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.student.id)
          .snapshots(),
      builder: (context, snapshot) {
        int streakDays = 0;
        List<DateTime> activeDates = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          streakDays = userData['streakDays'] ?? 0;

          final lastActive = userData['lastActiveDate'];
          if (lastActive != null) {
            // Generate some activity dates based on streak
            final lastDate = (lastActive as dynamic).toDate() as DateTime;
            for (int i = 0; i < streakDays && i < 7; i++) {
              activeDates.add(lastDate.subtract(Duration(days: i)));
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    '$streakDays Day Streak',
                    style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ADHDTheme.accentOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ADHDTheme.spacingSmall),
              Text(
                'Keep learning every day!',
                style: ADHDTheme.studentTextTheme.bodyMedium?.copyWith(
                  color: ADHDTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassroomInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.student.classId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final classData = snapshot.data!.data() as Map<String, dynamic>;
        final className = classData['name'] ?? 'My Class';
        final grade = classData['grade'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
            border: Border.all(
              color: ADHDTheme.primaryBlue.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ADHDTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: ADHDTheme.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: ADHDTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ADHDTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Grade $grade',
                      style: ADHDTheme.studentTextTheme.bodyMedium?.copyWith(
                        color: ADHDTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLessonsSection() {
    final isRTL = LocalizationService.instance.isRTL;

    return StreamBuilder<List<LessonModel>>(
      stream: LessonService.instance.classLessonsStream(widget.student.classId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(ADHDTheme.spacingLarge),
              child: CircularProgressIndicator(
                color: ADHDTheme.primaryBlue,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
            decoration: BoxDecoration(
              color: ADHDTheme.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
            ),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: ADHDTheme.spacingSmall),
                Expanded(
                  child: Text(
                    'Could not load lessons',
                    style: ADHDTheme.studentTextTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          );
        }

        final lessons = snapshot.data ?? [];

        if (lessons.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
            decoration: BoxDecoration(
              color: ADHDTheme.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
              border: Border.all(
                color: ADHDTheme.accentOrange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text('📚', style: TextStyle(fontSize: 64)),
                const SizedBox(height: ADHDTheme.spacingMedium),
                Text(
                  isRTL ? 'אין שיעורים חדשים' : 'No new lessons yet',
                  style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ADHDTheme.spacingSmall),
                Text(
                  isRTL
                      ? 'המורה שלך יעלה שיעורים בקרוב!'
                      : 'Your teacher will post lessons soon!',
                  style: ADHDTheme.studentTextTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Show up to 3 most recent lessons with completion status
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.student.id)
              .snapshots(),
          builder: (context, userSnapshot) {
            final completedLessons = <String>[];
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final completed = userData['completedLessons'] as List? ?? [];
              completedLessons.addAll(completed.cast<String>());
            }

            return Column(
              children: [
                ...lessons.take(3).map((lesson) {
                  final isCompleted = completedLessons.contains(lesson.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ADHDTheme.spacingMedium),
                    child: MissionCard(
                      icon: _getLessonIcon(lesson.topic),
                      title: lesson.title,
                      subtitle: lesson.description ?? 'Tap to start learning!',
                      durationMinutes: 10,
                      points: lesson.activities.isNotEmpty
                          ? lesson.activities.fold(0, (sum, a) => sum + a.points)
                          : 10,
                      isCompleted: isCompleted,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StudentLessonViewer(
                              lessonId: lesson.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                if (lessons.length > 3)
                  TextButton.icon(
                    onPressed: () {
                      // Could navigate to all tasks screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRTL
                                ? 'צופה בתור ${widget.student.fullName}'
                                : 'Viewing as ${widget.student.fullName}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: Text(
                      isRTL ? 'הצג את כל השיעורים' : 'View all lessons',
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoClassMessage() {
    final isRTL = LocalizationService.instance.isRTL;

    return Container(
      padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text('🏫', style: TextStyle(fontSize: 64)),
          const SizedBox(height: ADHDTheme.spacingMedium),
          Text(
            isRTL ? 'התלמיד לא משויך לכיתה' : 'Student not assigned to a class',
            style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingSmall),
          Text(
            isRTL
                ? 'שייך את התלמיד לכיתה כדי לראות שיעורים'
                : 'Assign the student to a class to see lessons',
            style: ADHDTheme.studentTextTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
