import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../admin/services/admin_service.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/student_creation_form.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Screen for admins to manage students
class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
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

  /// Show dialog to create new student
  Future<void> _showCreateStudentDialog() async {
    final isRTL = LocalizationService.instance.isRTL;
    final result = await showStudentCreationForm(context);

    if (result == true && mounted) {
      // After creating student, admin needs to log back in
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(isRTL ? 'תלמיד נוצר בהצלחה!' : 'Student Created Successfully!'),
          content: Text(
            isRTL
                ? 'התלמיד נוצר בהצלחה. אנא התחבר שוב.'
                : 'The student has been created successfully. Please log in again.',
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
              child: Text(isRTL ? 'התחבר שוב' : 'Log In Again'),
            ),
          ],
        ),
      );
    }
  }

  /// Delete student with confirmation
  Future<void> _deleteStudent(UserModel student) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final isRTL = LocalizationService.instance.isRTL;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'מחיקת תלמיד' : 'Delete Student'),
        content: Text(
          isRTL
              ? 'האם אתה בטוח שברצונך למחוק את התלמיד "${student.fullName}"?'
              : 'Are you sure you want to delete student "${student.fullName}"?',
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
        await AdminService.instance.deleteStudent(user.uid, student.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL ? 'התלמיד נמחק בהצלחה' : 'Student deleted successfully',
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
                isRTL ? 'שגיאה במחיקת תלמיד: $e' : 'Error deleting student: $e',
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
          isRTL ? 'ניהול תלמידים' : 'Manage Students',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Create new student button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
            child: IconButton(
              icon: const Icon(
                Icons.group_add,
                color: AppColors.secondary,
                size: 28,
              ),
              onPressed: _showCreateStudentDialog,
              tooltip: isRTL ? 'צור תלמיד חדש' : 'Create New Student',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: AdminService.instance.studentsStream(user.uid),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.secondary,
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
                    isRTL ? 'שגיאה בטעינת תלמידים' : 'Error loading students',
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

          final students = snapshot.data ?? [];

          // Empty state
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      size: 80,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    isRTL ? 'אין תלמידים עדיין' : 'No Students Yet',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    isRTL
                        ? 'לחץ על + ליצירת התלמיד הראשון'
                        : 'Click the + button to create your first student',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),
                  ElevatedButton.icon(
                    onPressed: _showCreateStudentDialog,
                    icon: const Icon(Icons.group_add),
                    label: Text(isRTL ? 'צור תלמיד' : 'Create Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
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

          // List of students
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _buildStudentCard(student, isRTL);
            },
          );
        },
      ),
    );
  }

  /// Build student card
  Widget _buildStudentCard(UserModel student, bool isRTL) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: student name and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${student.userName}',
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
                  onPressed: () => _deleteStudent(student),
                  tooltip: isRTL ? 'מחק תלמיד' : 'Delete Student',
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            const Divider(),
            const SizedBox(height: AppTheme.spacingSmall),

            // Student details
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: isRTL ? 'אימייל' : 'Email',
              value: student.email ?? '',
              isRTL: isRTL,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(
              icon: Icons.grade_outlined,
              label: isRTL ? 'כיתה' : 'Grade',
              value: student.grade?.toString() ?? 'N/A',
              isRTL: isRTL,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(
              icon: Icons.school_outlined,
              label: isRTL ? 'בית ספר' : 'School',
              value: student.schoolName,
              isRTL: isRTL,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(
              icon: Icons.location_city_outlined,
              label: isRTL ? 'עיר' : 'City',
              value: student.city,
              isRTL: isRTL,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(
              icon: Icons.stars_outlined,
              label: isRTL ? 'נקודות XP' : 'XP Points',
              value: student.xpPoints.toString(),
              isRTL: isRTL,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildInfoRow(
              icon: Icons.trending_up_outlined,
              label: isRTL ? 'רמה' : 'Level',
              value: student.currentLevel.toString(),
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
