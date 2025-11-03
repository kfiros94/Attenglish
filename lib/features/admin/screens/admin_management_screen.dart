import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../admin/services/admin_service.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/teacher_creation_form.dart';
import '../widgets/admin_creation_form.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// Screen for admins to manage teachers
class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
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

  /// Show menu to choose what to create
  Future<void> _showCreateMenu() async {
    final isRTL = LocalizationService.instance.isRTL;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: [
        PopupMenuItem(
          value: 'teacher',
          child: Row(
            children: [
              const Icon(Icons.person_add, color: AppColors.primary),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(AppStrings.createTeacher(_currentLocale)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'admin',
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: AppColors.accent),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(isRTL ? 'צור מנהל' : 'Create Admin'),
            ],
          ),
        ),
      ],
    );

    if (result == 'teacher') {
      await _showCreateTeacherDialog();
    } else if (result == 'admin') {
      await _showCreateAdminDialog();
    }
  }

  /// Show dialog to create new teacher
  Future<void> _showCreateTeacherDialog() async {
    final isRTL = LocalizationService.instance.isRTL;
    final result = await showTeacherCreationForm(context);

    if (result == true && mounted) {
      // After creating teacher, admin needs to log back in
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.teacherCreatedSuccess(_currentLocale)),
          content: Text(AppStrings.teacherCreatedLoginAgain(_currentLocale)),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Sign out and go to login
                await AuthService.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: Text(AppStrings.loginAgain(_currentLocale)),
            ),
          ],
        ),
      );
    }
  }

  /// Show dialog to create new admin
  Future<void> _showCreateAdminDialog() async {
    final isRTL = LocalizationService.instance.isRTL;
    final result = await showAdminCreationForm(context);

    if (result == true && mounted) {
      // After creating admin, current admin needs to log back in
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(isRTL ? 'מנהל נוצר בהצלחה!' : 'Admin Created Successfully!'),
          content: Text(
            isRTL
                ? 'המנהל נוצר בהצלחה. אנא התחבר שוב.'
                : 'The admin has been created successfully. Please log in again.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Sign out and go to login
                await AuthService.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: Text(AppStrings.loginAgain(_currentLocale)),
            ),
          ],
        ),
      );
    }
  }

  /// Delete teacher with confirmation
  Future<void> _deleteTeacher(UserModel teacher) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final isRTL = LocalizationService.instance.isRTL;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'מחיקת מורה' : 'Delete Teacher'),
        content: Text(
          isRTL
              ? 'האם אתה בטוח שברצונך למחוק את המורה "${teacher.fullName}"?'
              : 'Are you sure you want to delete teacher "${teacher.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              isRTL ? 'ביטול' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isRTL ? 'מחק' : 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await AdminService.instance.deleteTeacher(user.uid, teacher.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL ? 'המורה נמחק בהצלחה' : 'Teacher deleted successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL ? 'שגיאה במחיקת מורה: $e' : 'Error deleting teacher: $e',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final isRTL = LocalizationService.instance.isRTL;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            isRTL ? 'לא מחובר' : 'Not logged in',
            style: const TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isRTL ? 'ניהול מורים' : 'Manage Teachers',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Create new user button (teacher or admin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
            child: IconButton(
              icon: const Icon(
                Icons.person_add,
                color: AppColors.primary,
                size: 28,
              ),
              onPressed: _showCreateMenu,
              tooltip: isRTL ? 'צור משתמש חדש' : 'Create New User',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: AdminService.instance.teachersStream(user.uid),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    isRTL ? 'שגיאה בטעינת מורים' : 'Error loading teachers',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final teachers = snapshot.data ?? [];

          // Empty state
          if (teachers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    isRTL ? 'אין מורים עדיין' : 'No Teachers Yet',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    isRTL
                        ? 'לחץ על + ליצירת המורה הראשון'
                        : 'Click the + button to create your first teacher',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),
                  ElevatedButton.icon(
                    onPressed: _showCreateTeacherDialog,
                    icon: const Icon(Icons.person_add),
                    label: Text(isRTL ? 'צור מורה' : 'Create Teacher'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                        vertical: AppTheme.spacingMedium,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // List of teachers
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return _buildTeacherCard(teacher, isRTL);
            },
          );
        },
      ),
    );
  }

  /// Build teacher card
  Widget _buildTeacherCard(UserModel teacher, bool isRTL) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: teacher name and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.fullName,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${teacher.userName}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: () => _deleteTeacher(teacher),
                  tooltip: isRTL ? 'מחק מורה' : 'Delete Teacher',
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            const Divider(),
            const SizedBox(height: AppTheme.spacingSmall),

            // Teacher details
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: isRTL ? 'אימייל' : 'Email',
              value: teacher.email ?? '',
              isRTL: isRTL,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(
              icon: Icons.school_outlined,
              label: isRTL ? 'בית ספר' : 'School',
              value: teacher.schoolName,
              isRTL: isRTL,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(
              icon: Icons.location_city_outlined,
              label: isRTL ? 'עיר' : 'City',
              value: teacher.city,
              isRTL: isRTL,
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isRTL,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
