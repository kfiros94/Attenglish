import 'package:flutter/material.dart';
import '../services/class_service.dart';
import '../models/class_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// Form dialog for teachers to create student accounts for their classroom
class TeacherStudentCreationForm extends StatefulWidget {
  final ClassModel classroom;

  const TeacherStudentCreationForm({
    super.key,
    required this.classroom,
  });

  @override
  State<TeacherStudentCreationForm> createState() =>
      _TeacherStudentCreationFormState();
}

class _TeacherStudentCreationFormState
    extends State<TeacherStudentCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Parent details controllers
  final _parentFullNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _parentFullNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  /// Validate and create student account
  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ClassService.instance.createStudentForClass(
        classId: widget.classroom.id,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        userName: _userNameController.text.trim(),
        parentFullName: _parentFullNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        parentEmail: _parentEmailController.text.trim().isNotEmpty
            ? _parentEmailController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
      }
    } catch (e) {
      if (mounted) {
        final isRTL = LocalizationService.instance.isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'שגיאה ביצירת תלמיד: $e' : 'Error creating student: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;
    final locale = LocalizationService.instance.currentLocale;

    return AlertDialog(
      // Constrain dialog width for better UX (Shneiderman Rule 5: Prevent Errors)
      constraints: const BoxConstraints(maxWidth: 480),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.person_add,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRTL ? 'יצירת תלמיד חדש' : 'Create New Student',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${widget.classroom.name} - Grade ${widget.classroom.grade}',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner about auto-assignment
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRTL
                            ? 'התלמיד ישוייך אוטומטית לכיתה זו'
                            : 'Student will be automatically added to this class',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: AppStrings.fullName(locale),
                  hintText: isRTL ? 'שם מלא' : 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnter(
                        locale, AppStrings.fullName(locale));
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Username
              TextFormField(
                controller: _userNameController,
                decoration: InputDecoration(
                  labelText: AppStrings.username(locale),
                  hintText: isRTL ? 'שם משתמש' : 'username123',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnter(
                        locale, AppStrings.username(locale));
                  }
                  if (value.contains(' ')) {
                    return isRTL
                        ? 'שם משתמש לא יכול להכיל רווחים'
                        : 'Username cannot contain spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.email(locale),
                  hintText: 'student@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnterEmail(locale);
                  }
                  if (!value.contains('@')) {
                    return AppStrings.pleaseEnterValidEmail(locale);
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: AppStrings.password(locale),
                  hintText: AppStrings.passwordHint(locale),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.pleaseEnterPassword(locale);
                  }
                  if (value.length < 6) {
                    return AppStrings.passwordTooShort(locale);
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: AppStrings.confirmPassword(locale),
                  hintText: AppStrings.confirmPasswordHint(locale),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.pleaseConfirmPassword(locale);
                  }
                  if (value != _passwordController.text) {
                    return AppStrings.passwordsDoNotMatch(locale);
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingLarge),

              // Parent Details Section
              Text(
                isRTL ? 'פרטי הורה' : 'Parent Details',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Parent Full Name
              TextFormField(
                controller: _parentFullNameController,
                decoration: InputDecoration(
                  labelText: isRTL ? 'שם מלא של ההורה' : 'Parent Full Name',
                  hintText: isRTL ? 'שם ההורה' : 'Parent name',
                  prefixIcon: const Icon(Icons.family_restroom),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRTL
                        ? 'אנא הכנס שם הורה'
                        : 'Please enter parent name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Parent Phone
              TextFormField(
                controller: _parentPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isRTL ? 'טלפון הורה' : 'Parent Phone',
                  hintText: isRTL ? '050-1234567' : '050-1234567',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRTL
                        ? 'אנא הכנס טלפון הורה'
                        : 'Please enter parent phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Parent Email (Optional)
              TextFormField(
                controller: _parentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: isRTL ? 'אימייל הורה (אופציונלי)' : 'Parent Email (Optional)',
                  hintText: 'parent@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  // Email is optional, but if provided, must be valid
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@')) {
                      return isRTL
                          ? 'אנא הכנס אימייל תקין'
                          : 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            AppStrings.cancel(locale),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTheme.fontSizeMedium,
            ),
          ),
        ),

        // Create button
        ElevatedButton(
          onPressed: _isLoading ? null : _createStudent,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLarge,
              vertical: AppTheme.spacingSmall,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Text(
                  AppStrings.create(locale),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Show teacher student creation form dialog
Future<bool?> showTeacherStudentCreationForm(
  BuildContext context,
  ClassModel classroom,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => TeacherStudentCreationForm(classroom: classroom),
  );
}
