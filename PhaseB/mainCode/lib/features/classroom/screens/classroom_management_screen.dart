import 'package:flutter/material.dart';
import '../../classroom/models/class_model.dart';
import '../../classroom/services/class_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../widgets/classroom_form_dialog.dart';
import 'student_assignment_screen.dart';

/// Screen for teachers to manage their classrooms
class ClassroomManagementScreen extends StatefulWidget {
  const ClassroomManagementScreen({super.key});

  @override
  State<ClassroomManagementScreen> createState() =>
      _ClassroomManagementScreenState();
}

class _ClassroomManagementScreenState extends State<ClassroomManagementScreen> {
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

  /// Show dialog to create new classroom
  Future<void> _showCreateClassroomDialog() async {
    final isRTL = LocalizationService.instance.isRTL;
    final result = await showClassroomFormDialog(context);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRTL ? 'הכיתה נוצרה בהצלחה!' : 'Classroom created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Navigate to classroom details (student roster)
  void _viewClassroomDetails(ClassModel classroom) {
    // TODO: Implement classroom detail screen in future
    final isRTL = LocalizationService.instance.isRTL;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRTL
              ? 'תצוגת כיתה ${classroom.name} - בפיתוח'
              : 'Viewing ${classroom.name} - Coming soon',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Delete classroom with confirmation
  Future<void> _deleteClassroom(ClassModel classroom) async {
    final isRTL = LocalizationService.instance.isRTL;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'מחיקת כיתה' : 'Delete Classroom'),
        content: Text(
          isRTL
              ? 'האם אתה בטוח שברצונך למחוק את הכיתה "${classroom.name}"?'
              : 'Are you sure you want to delete classroom "${classroom.name}"?',
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
        await ClassService.instance.deleteClass(classroom.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL ? 'הכיתה נמחקה בהצלחה' : 'Classroom deleted successfully',
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
                isRTL ? 'שגיאה במחיקת כיתה: $e' : 'Error deleting classroom: $e',
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
          isRTL ? 'ניהול כיתות' : 'Manage Classrooms',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Create new classroom button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
            child: IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 28,
              ),
              onPressed: _showCreateClassroomDialog,
              tooltip: isRTL ? 'יצירת כיתה חדשה' : 'Create New Classroom',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: ClassService.instance.teacherClassesStream(user.uid),
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
                    isRTL ? 'שגיאה בטעינת כיתות' : 'Error loading classrooms',
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

          final classrooms = snapshot.data ?? [];

          // Empty state
          if (classrooms.isEmpty) {
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
                      Icons.school_outlined,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    isRTL ? 'אין כיתות עדיין' : 'No Classrooms Yet',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    isRTL
                        ? 'לחץ על + ליצירת הכיתה הראשונה שלך'
                        : 'Click the + button to create your first classroom',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),
                  ElevatedButton.icon(
                    onPressed: _showCreateClassroomDialog,
                    icon: const Icon(Icons.add),
                    label: Text(isRTL ? 'צור כיתה' : 'Create Classroom'),
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

          // List of classrooms
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: classrooms.length,
            itemBuilder: (context, index) {
              final classroom = classrooms[index];
              return _buildClassroomCard(classroom, isRTL);
            },
          );
        },
      ),
    );
  }

  /// Build classroom card
  Widget _buildClassroomCard(ClassModel classroom, bool isRTL) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: InkWell(
        onTap: () => _viewClassroomDetails(classroom),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: classroom name and actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.class_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom.name,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRTL
                              ? 'כיתה ${classroom.grade}'
                              : 'Grade ${classroom.grade}',
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
                    onPressed: () => _deleteClassroom(classroom),
                    tooltip: isRTL ? 'מחק כיתה' : 'Delete Classroom',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              const Divider(),
              const SizedBox(height: AppTheme.spacingSmall),

              // Classroom details
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people_outline,
                    label: isRTL ? 'תלמידים' : 'Students',
                    value: classroom.studentIds.length.toString(),
                    isRTL: isRTL,
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  _buildInfoChip(
                    icon: Icons.school_outlined,
                    label: isRTL ? 'בית ספר' : 'School',
                    value: classroom.schoolName,
                    isRTL: isRTL,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Manage Students button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentAssignmentScreen(classroom: classroom),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 18),
                  label: Text(
                    isRTL ? 'ניהול תלמידים' : 'Manage Students',
                    style: const TextStyle(fontSize: AppTheme.fontSizeMedium),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingSmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build info chip
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isRTL,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall,
          vertical: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
