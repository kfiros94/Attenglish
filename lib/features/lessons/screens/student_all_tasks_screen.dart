import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../../../core/theme/adhd_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';
import '../../../features/auth/services/auth_service.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import 'student_lesson_viewer.dart';

/// All Tasks Screen
/// Shows all available lessons/tasks for the student
/// Not just today's mission, but the complete task history
class StudentAllTasksScreen extends StatefulWidget {
  const StudentAllTasksScreen({super.key});

  @override
  State<StudentAllTasksScreen> createState() => _StudentAllTasksScreenState();
}

class _StudentAllTasksScreenState extends State<StudentAllTasksScreen> {
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

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;
    final isRTL = LocalizationService.instance.isRTL;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.allMyTasks(_currentLocale)),
        ),
        body: const Center(
          child: Text('Please log in to view tasks'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ADHDTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          AppStrings.allMyTasks(_currentLocale),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: ADHDTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ADHDTheme.primaryBlue),
      ),
      body: FutureBuilder<String?>(
        future: _getClassId(userId),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ADHDTheme.primaryBlue,
              ),
            );
          }

          final classId = classSnapshot.data;

          if (classId == null) {
            return _buildNoClassroomMessage(isRTL);
          }

          return StreamBuilder<List<LessonModel>>(
            stream: LessonService.instance.classLessonsStream(classId),
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
                return _buildErrorMessage(isRTL);
              }

              final lessons = snapshot.data ?? [];

              if (lessons.isEmpty) {
                return _buildNoLessonsMessage(isRTL);
              }

              return _buildLessonsList(lessons, isRTL);
            },
          );
        },
      ),
    );
  }

  /// Get class ID for current user
  Future<String?> _getClassId(String userId) async {
    try {
      final userData = await AuthService.instance.getUserData(userId);
      return userData?.classId;
    } catch (e) {
      debugPrint('Error getting class ID: $e');
      return null;
    }
  }

  /// Check if lesson is new (created within last 7 days)
  bool _isLessonNew(LessonModel lesson) {
    final now = DateTime.now();
    final difference = now.difference(lesson.createdAt);
    return difference.inDays <= 7;
  }

  /// Build lessons list with GetWidget cards
  Widget _buildLessonsList(List<LessonModel> lessons, bool isRTL) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count
          GFCard(
            color: ADHDTheme.primaryBlue.withOpacity(0.1),
            elevation: 0,
            content: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 32)),
                const SizedBox(width: ADHDTheme.spacingSmall),
                Expanded(
                  child: Text(
                    isRTL
                        ? 'יש לך ${lessons.length} משימות זמינות'
                        : 'You have ${lessons.length} available tasks',
                    style: const TextStyle(
                      fontSize: ADHDTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: ADHDTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingLarge),

          // All lessons using GetWidget cards
          ...lessons.map((lesson) {
            final isNew = _isLessonNew(lesson);
            return Padding(
              padding: const EdgeInsets.only(bottom: ADHDTheme.spacingMedium),
              child: GFCard(
                boxFit: BoxFit.cover,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                ),
                content: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StudentLessonViewer(
                          lessonId: lesson.id,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with icon, title, and NEW badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Lesson icon
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: ADHDTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    ADHDTheme.radiusSmall),
                              ),
                              child: Center(
                                child: Text(
                                  _getLessonIcon(lesson.topic),
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                            const SizedBox(width: ADHDTheme.spacingMedium),

                            // Title and subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lesson.title,
                                          style: const TextStyle(
                                            fontSize: ADHDTheme.fontSizeLarge,
                                            fontWeight: FontWeight.bold,
                                            color: ADHDTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      // NEW badge (only if created within last 7 days)
                                      if (isNew)
                                        GFBadge(
                                          text: 'NEW',
                                          color: ADHDTheme.primaryBlue,
                                          textColor: Colors.white,
                                          shape: GFBadgeShape.pills,
                                          size: GFSize.SMALL,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lesson.description ??
                                        (isRTL
                                            ? 'שיעור מהמורה שלך'
                                            : 'Lesson from your teacher'),
                                    style: const TextStyle(
                                      fontSize: ADHDTheme.fontSizeSmall,
                                      color: ADHDTheme.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ADHDTheme.spacingMedium),

                        // Info row: Duration and Points
                        Row(
                          children: [
                            // Duration
                            GFButton(
                              onPressed: null,
                              text: isRTL ? '5 דקות ⏱️' : '⏱️ 5 min',
                              size: GFSize.SMALL,
                              type: GFButtonType.outline,
                              color: ADHDTheme.secondaryGreen,
                              disabledColor: ADHDTheme.secondaryGreen,
                              disabledTextColor: ADHDTheme.secondaryGreen,
                              shape: GFButtonShape.pills,
                            ),
                            const SizedBox(width: ADHDTheme.spacingSmall),

                            // Points
                            GFButton(
                              onPressed: null,
                              text: isRTL
                                  ? '${_calculatePoints(lesson.difficulty)} נקודות ⭐'
                                  : '⭐ +${_calculatePoints(lesson.difficulty)} pts',
                              size: GFSize.SMALL,
                              type: GFButtonType.outline,
                              color: ADHDTheme.accentOrange,
                              disabledColor: ADHDTheme.accentOrange,
                              disabledTextColor: ADHDTheme.accentOrange,
                              shape: GFButtonShape.pills,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build no classroom message
  Widget _buildNoClassroomMessage(bool isRTL) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
        child: Container(
          padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
          decoration: BoxDecoration(
            color: ADHDTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 64)),
              const SizedBox(height: ADHDTheme.spacingMedium),
              Text(
                isRTL ? 'אין כיתה עדיין' : 'No Classroom Yet',
                style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: ADHDTheme.spacingSmall),
              Text(
                isRTL
                    ? 'המורה שלך יוסיף אותך לכיתה בקרוב'
                    : 'Your teacher will add you to a classroom soon',
                style: ADHDTheme.studentTextTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build no lessons message
  Widget _buildNoLessonsMessage(bool isRTL) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📚', style: TextStyle(fontSize: 64)),
              const SizedBox(height: ADHDTheme.spacingMedium),
              Text(
                isRTL ? 'אין שיעורים עדיין' : 'No Lessons Yet',
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
        ),
      ),
    );
  }

  /// Build error message
  Widget _buildErrorMessage(bool isRTL) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
        child: Container(
          padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
          decoration: BoxDecoration(
            color: ADHDTheme.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: ADHDTheme.spacingSmall),
              Text(
                isRTL ? 'לא ניתן לטעון שיעורים' : 'Could not load lessons',
                style: ADHDTheme.studentTextTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get appropriate icon for lesson based on topic
  String _getLessonIcon(String? topic) {
    if (topic == null) return '📚';

    final topicLower = topic.toLowerCase();
    if (topicLower.contains('grammar')) return '📝';
    if (topicLower.contains('vocabulary')) return '📖';
    if (topicLower.contains('reading')) return '📕';
    if (topicLower.contains('writing')) return '✍️';
    if (topicLower.contains('speaking')) return '🗣️';
    if (topicLower.contains('listening')) return '👂';
    if (topicLower.contains('color')) return '🎨';
    if (topicLower.contains('number')) return '🔢';
    if (topicLower.contains('animal')) return '🐾';
    if (topicLower.contains('food')) return '🍕';

    return '📚';
  }

  /// Calculate points based on difficulty
  int _calculatePoints(int difficulty) {
    switch (difficulty) {
      case 1:
        return 10;
      case 2:
        return 20;
      case 3:
        return 30;
      case 4:
        return 40;
      case 5:
        return 50;
      default:
        return 20;
    }
  }
}
