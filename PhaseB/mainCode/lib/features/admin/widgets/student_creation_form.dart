import 'package:flutter/material.dart';
import '../../admin/services/admin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// Form dialog for admins to create student accounts
class StudentCreationForm extends StatefulWidget {
  const StudentCreationForm({super.key});

  @override
  State<StudentCreationForm> createState() => _StudentCreationFormState();
}

class _StudentCreationFormState extends State<StudentCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _gradeController = TextEditingController();

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
    _schoolNameController.dispose();
    _cityController.dispose();
    _gradeController.dispose();
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
      await AdminService.instance.createStudent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        userName: _userNameController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
        city: _cityController.text.trim(),
        grade: int.parse(_gradeController.text.trim()),
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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.group_add,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Text(
              isRTL ? 'יצירת חשבון תלמיד' : 'Create Student Account',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
              // Personal Information Section
              Text(
                AppStrings.personalInformation(locale),
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: AppStrings.fullName(locale),
                  hintText: isRTL ? 'ג\'ון דו' : 'John Doe',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnter(locale, AppStrings.fullName(locale));
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
                  hintText: isRTL ? 'תלמיד123' : 'student123',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnter(locale, AppStrings.username(locale));
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingLarge),

              // Account Information Section
              Text(
                AppStrings.accountInformation(locale),
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.email(locale),
                  hintText: isRTL ? 'student@example.com' : 'student@example.com',
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
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
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

              // School Information Section
              Text(
                AppStrings.schoolInformation(locale),
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // School Name
              TextFormField(
                controller: _schoolNameController,
                decoration: InputDecoration(
                  labelText: AppStrings.schoolName(locale),
                  hintText: AppStrings.schoolNameHint(locale),
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnter(locale, AppStrings.schoolName(locale));
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: AppStrings.city(locale),
                  hintText: AppStrings.cityHint(locale),
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnter(locale, AppStrings.city(locale));
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Grade (for students only)
              TextFormField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isRTL ? 'כיתה' : 'Grade',
                  hintText: isRTL ? '1-12' : '1-12',
                  prefixIcon: const Icon(Icons.grade_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  helperText: isRTL ? 'הכנס כיתה (1-12)' : 'Enter grade level (1-12)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isRTL ? 'אנא הכנס כיתה' : 'Please enter grade';
                  }
                  final grade = int.tryParse(value);
                  if (grade == null || grade < 1 || grade > 12) {
                    return isRTL ? 'כיתה חייבת להיות בין 1-12' : 'Grade must be between 1-12';
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

/// Show student creation form dialog
Future<bool?> showStudentCreationForm(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const StudentCreationForm(),
  );
}
