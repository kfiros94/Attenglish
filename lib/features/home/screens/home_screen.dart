import 'package:flutter/material.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/greeting_helper.dart';
import '../../classroom/widgets/classroom_info_widget.dart';
import '../widgets/dashboard_card.dart';
import '../../../shared/widgets/atti_mascot.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/achievement_badge.dart';
import '../../lessons/widgets/mission_card.dart';
import '../../lessons/models/lesson_model.dart';
import '../../lessons/services/lesson_service.dart';
import '../../lessons/screens/student_lesson_viewer.dart';
import '../../../core/theme/adhd_theme.dart';

/// Home screen with personalized greeting and user dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Locale _currentLocale = LocalizationService.instance.currentLocale;
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Listen to locale changes
    LocalizationService.instance.localeStream.listen((locale) {
      if (mounted) {
        setState(() {
          _currentLocale = locale;
        });
      }
    });
  }

  /// Load current user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final userData = await AuthService.instance.getUserData(user.uid);
        if (mounted) {
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
        }
      } else {
        // No user logged in, navigate to login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    try {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Build greeting text with icon
  Widget _buildGreeting() {
    if (_userData == null) return const SizedBox.shrink();

    final greeting = GreetingHelper.getGreeting(_currentLocale);
    final icon = GreetingHelper.getGreetingIcon();
    final name = _userData!.userName;

    final isRTL = LocalizationService.instance.isRTL;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isRTL) ...[
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppTheme.spacingSmall),
          ],
          Text(
            '$greeting, $name!',
            style: const TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRTL) ...[
            const SizedBox(width: AppTheme.spacingSmall),
            Text(icon, style: const TextStyle(fontSize: 20)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo/Attenglish_Logo.png',
              height: 80,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          // Greeting
          if (!_isLoading && _userData != null) _buildGreeting(),
          const SizedBox(width: AppTheme.spacingSmall),

          // Language toggle
          const LanguageToggle(size: 36),
          const SizedBox(width: AppTheme.spacingSmall),

          // Menu button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'admin') {
                Navigator.of(context).pushNamed('/admin');
              }
            },
            itemBuilder: (context) => [
              // Show "Manage Teachers" for admins
              if (_userData?.role == 'admin')
                PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: AppColors.accent),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        LocalizationService.instance.isRTL
                            ? 'ניהול מורים'
                            : 'Manage Teachers',
                      ),
                    ],
                  ),
                ),
              // Removed "My Classrooms" from menu - now on dashboard
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppColors.error),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(AppStrings.signOut(_currentLocale)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _userData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      Text(
                        AppStrings.errorOccurred(_currentLocale),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: Text(AppStrings.tryAgain(_currentLocale)),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    child: _userData!.role == 'teacher'
                        ? _buildTeacherDashboard()
                        : _buildStudentView(),
                  ),
                ),
    );
  }

  /// Build professional teacher dashboard
  Widget _buildTeacherDashboard() {
    final isRTL = LocalizationService.instance.isRTL;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact mascot with message
        Center(
          child: MascotWidget(
            message: isRTL
                ? 'מוכן ללמד היום?'
                : 'Ready to teach today?',
            size: 100,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),

        // Dashboard title
        Text(
          isRTL ? 'לוח הבקרה שלי' : 'Dashboard',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),

        // Dashboard grid
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.spacingMedium,
              crossAxisSpacing: AppTheme.spacingMedium,
              childAspectRatio: 1.1,
              children: [
                // My Classrooms card
                DashboardCard(
                  icon: Icons.school,
                  iconColor: AppColors.primary,
                  title: isRTL ? 'הכיתות שלי' : 'My Classrooms',
                  description: isRTL
                      ? 'נהל את הכיתות והתלמידים שלך'
                      : 'Manage your classes and students',
                  onTap: () {
                    Navigator.of(context).pushNamed('/classrooms');
                  },
                ),

                // Student Progress card
                DashboardCard(
                  icon: Icons.analytics,
                  iconColor: AppColors.secondary,
                  title: isRTL ? 'התקדמות תלמידים' : 'Student Progress',
                  description: isRTL
                      ? 'צפה בדוחות והתקדמות'
                      : 'View reports and analytics',
                  badgeText: isRTL ? 'בקרוב' : 'Soon',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRTL
                              ? 'תכונה זו תהיה זמינה בקרוב'
                              : 'This feature is coming soon',
                        ),
                      ),
                    );
                  },
                ),

                // Create Lesson card
                DashboardCard(
                  icon: Icons.edit_note,
                  iconColor: AppColors.accent,
                  title: isRTL ? 'צור שיעור' : 'Create Lesson',
                  description: isRTL
                      ? 'העלה תוכן חדש ושיעורים'
                      : 'Upload new content and lessons',
                  onTap: () {
                    Navigator.of(context).pushNamed('/lessons/create');
                  },
                ),

                // Content Library card
                DashboardCard(
                  icon: Icons.library_books,
                  iconColor: Colors.purple,
                  title: isRTL ? 'ספריית תכנים' : 'Content Library',
                  description: isRTL
                      ? 'עיין בתכנים זמינים'
                      : 'Browse available content',
                  onTap: () {
                    Navigator.of(context).pushNamed('/lessons/list');
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Build student view (ADHD-friendly)
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
              _userData!.userName,
            ),
            size: AttiSize.large,
            showSpeechBubble: true,
          ),
        ),
        const SizedBox(height: ADHDTheme.spacingXLarge),

        // 2. Progress bar section
        StudentProgressBar(
          level: 3, // TODO: Get from user data
          currentXP: 250, // TODO: Get from user data
          maxXP: 500, // TODO: Calculate based on level
          streakDays: 5, // TODO: Get from user data
        ),
        const SizedBox(height: ADHDTheme.spacingXLarge),

        // 3. Classroom info (only for students)
        if (_userData!.role == 'student') ...[
          const ClassroomInfoWidget(),
          const SizedBox(height: ADHDTheme.spacingXLarge),
        ],

        // 4. Today's Mission section header
        Row(
          children: [
            Text(
              '🎯',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: ADHDTheme.spacingSmall),
            Text(
              isRTL ? 'המשימה שלך היום' : 'Today\'s Mission',
              style: ADHDTheme.studentTextTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ADHDTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: ADHDTheme.spacingMedium),

        // 5. Mission cards (real lessons from teacher)
        if (_userData!.classId != null)
          StreamBuilder<List<LessonModel>>(
            stream: LessonService.instance.classLessonsStream(_userData!.classId!),
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

              // Show up to 3 most recent lessons
              return Column(
                children: lessons.take(3).map((lesson) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ADHDTheme.spacingMedium),
                    child: MissionCard(
                      icon: _getLessonIcon(lesson.topic),
                      title: lesson.title,
                      subtitle: lesson.description ??
                          (isRTL ? 'שיעור חדש מהמורה שלך!' : 'New lesson from your teacher!'),
                      durationMinutes: 5,
                      points: _calculatePoints(lesson.difficulty),
                      type: MissionType.lesson,
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
                }).toList(),
              );
            },
          )
        else
          // Student not assigned to classroom yet
          Container(
            padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
            decoration: BoxDecoration(
              color: ADHDTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
            ),
            child: Column(
              children: [
                const Text('👋', style: TextStyle(fontSize: 64)),
                const SizedBox(height: ADHDTheme.spacingMedium),
                Text(
                  isRTL ? 'ברוך הבא!' : 'Welcome!',
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

        const SizedBox(height: ADHDTheme.spacingLarge),

        // 6. Small Atti with encouragement
        Center(
          child: AttiMascot(
            message: AttiMessages.getRandomEncouragement(),
            size: AttiSize.small,
            position: AttiPosition.left,
            showSpeechBubble: true,
          ),
        ),
        const SizedBox(height: ADHDTheme.spacingXLarge),

        // 7. Achievements section
        AchievementSection(
          achievements: Achievement.getSampleAchievements(),
        ),
      ],
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
