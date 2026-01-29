import 'package:flutter/material.dart';
import '../../classroom/models/class_model.dart';
import '../../classroom/services/class_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Widget displaying classroom information for students
class ClassroomInfoWidget extends StatefulWidget {
  const ClassroomInfoWidget({super.key});

  @override
  State<ClassroomInfoWidget> createState() => _ClassroomInfoWidgetState();
}

class _ClassroomInfoWidgetState extends State<ClassroomInfoWidget> {
  ClassModel? _classroom;
  UserModel? _teacher;
  bool _isLoading = true;
  Locale _currentLocale = LocalizationService.instance.currentLocale;

  @override
  void initState() {
    super.initState();
    _loadClassroomInfo();

    // Listen to locale changes
    LocalizationService.instance.localeStream.listen((locale) {
      if (mounted) {
        setState(() {
          _currentLocale = locale;
        });
      }
    });
  }

  Future<void> _loadClassroomInfo() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final classroom = await ClassService.instance.getStudentClass(user.uid);
        if (classroom != null && mounted) {
          // Get teacher info
          final teacherData =
              await AuthService.instance.getUserData(classroom.teacherId);
          setState(() {
            _classroom = classroom;
            _teacher = teacherData;
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    if (_isLoading) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Text(
                isRTL ? 'טוען...' : 'Loading...',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_classroom == null) {
      return Card(
        elevation: 2,
        color: AppColors.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Text(
                  isRTL ? 'לא משובץ לכיתה עדיין' : 'Not assigned to a class yet',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _classroom!.name,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRTL
                            ? 'כיתה ${_classroom!.grade}'
                            : 'Grade ${_classroom!.grade}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_teacher != null) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              const Divider(),
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    isRTL ? 'מורה:' : 'Teacher:',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    _teacher!.fullName,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
