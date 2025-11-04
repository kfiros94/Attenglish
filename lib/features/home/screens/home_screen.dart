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

                // Content Library card
                DashboardCard(
                  icon: Icons.library_books,
                  iconColor: Colors.purple,
                  title: isRTL ? 'ספריית תכנים' : 'Content Library',
                  description: isRTL
                      ? 'עיין בתכנים זמינים'
                      : 'Browse available content',
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

        // 5. Mission cards (placeholder data)
        MissionCard(
          icon: '📚',
          title: isRTL ? 'שיעור חדש: צבעים' : 'New Lesson: Colors',
          subtitle: isRTL ? 'למד 10 מילים חדשות של צבעים!' : 'Learn 10 new color words!',
          durationMinutes: 5,
          points: 20,
          type: MissionType.lesson,
          onTap: () {
            // TODO: Navigate to lesson
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isRTL ? 'השיעורים יתווספו בקרוב' : 'Lessons coming soon',
                ),
                backgroundColor: ADHDTheme.primaryBlue,
              ),
            );
          },
        ),
        const SizedBox(height: ADHDTheme.spacingMedium),

        MissionCard(
          icon: '🔄',
          title: isRTL ? 'תרגול: מספרים' : 'Practice: Numbers',
          subtitle: isRTL ? 'חזור על מה שלמדת' : 'Review what you learned',
          durationMinutes: 3,
          points: 10,
          type: MissionType.practice,
          onTap: () {
            // TODO: Navigate to practice
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isRTL ? 'תרגולים יתווספו בקרוב' : 'Practice coming soon',
                ),
                backgroundColor: ADHDTheme.secondaryGreen,
              ),
            );
          },
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

}
