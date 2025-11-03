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
            Text(
              AppStrings.appName(_currentLocale),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
              } else if (value == 'classrooms') {
                Navigator.of(context).pushNamed('/classrooms');
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
              // Show "My Classrooms" for teachers
              if (_userData?.role == 'teacher')
                PopupMenuItem(
                  value: 'classrooms',
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: AppColors.primary),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(AppStrings.myClassrooms(_currentLocale)),
                    ],
                  ),
                ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mascot with personalized message
                        MascotWidget(
                          message: GreetingHelper.getMascotMessage(
                            _currentLocale,
                            _userData!.userName,
                          ),
                          size: 120,
                        ),
                        const SizedBox(height: AppTheme.spacingXLarge),

                        // Welcome card
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLarge),
                            child: Column(
                              children: [
                                Text(
                                  AppStrings.welcomeToAttEnglish(_currentLocale),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacingMedium),
                                Text(
                                  '${AppStrings.loggedInAs(_currentLocale)} ${_userData!.email}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXLarge),

                        // Classroom info section (only for students)
                        if (_userData!.role == 'student') ...[
                          const ClassroomInfoWidget(),
                          const SizedBox(height: AppTheme.spacingXLarge),
                        ],

                        // User info section
                        _buildInfoCard(
                          LocalizationService.instance.isRTL
                              ? 'מידע אישי'
                              : 'Personal Information',
                          [
                            _buildInfoRow(
                              LocalizationService.instance.isRTL
                                  ? 'שם מלא'
                                  : 'Full Name',
                              _userData!.fullName,
                            ),
                            _buildInfoRow(
                              LocalizationService.instance.isRTL
                                  ? 'שם משתמש'
                                  : 'Username',
                              _userData!.userName,
                            ),
                            _buildInfoRow(
                              LocalizationService.instance.isRTL
                                  ? 'בית ספר'
                                  : 'School',
                              _userData!.schoolName,
                            ),
                            _buildInfoRow(
                              LocalizationService.instance.isRTL ? 'עיר' : 'City',
                              _userData!.city,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXLarge),

                        // Placeholder for lessons
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLarge),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.construction,
                                  size: 64,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(height: AppTheme.spacingMedium),
                                Text(
                                  LocalizationService.instance.isRTL
                                      ? 'השיעורים שלך'
                                      : 'Your Lessons',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacingSmall),
                                Text(
                                  LocalizationService.instance.isRTL
                                      ? 'השיעורים יתווספו בקרוב...'
                                      : 'Lessons coming soon...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build info card
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            const Divider(),
            const SizedBox(height: AppTheme.spacingSmall),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
