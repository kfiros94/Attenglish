import 'package:flutter/material.dart';
import '../../admin/services/admin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// Form dialog for admins to create teacher accounts
class TeacherCreationForm extends StatefulWidget {
  const TeacherCreationForm({super.key});

  @override
  State<TeacherCreationForm> createState() => _TeacherCreationFormState();
}

class _TeacherCreationFormState extends State<TeacherCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _cityController = TextEditingController();

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
    super.dispose();
  }

  /// Validate and create teacher account
  Future<void> _createTeacher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminService.instance.createTeacher(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        userName: _userNameController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
        city: _cityController.text.trim(),
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
              isRTL ? 'שגיאה ביצירת מורה: $e' : 'Error creating teacher: $e',
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.person_add,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Text(
              isRTL ? 'יצירת חשבון מורה' : 'Create Teacher Account',
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
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: AppStrings.fullName(locale),
                  hintText: AppStrings.fullNameHint(locale),
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
                  hintText: AppStrings.usernameHint(locale),
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
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.email(locale),
                  hintText: AppStrings.emailHint(locale),
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
                  color: AppColors.primary,
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
          onPressed: _isLoading ? null : _createTeacher,
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

/// Show teacher creation form dialog
Future<bool?> showTeacherCreationForm(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const TeacherCreationForm(),
  );
}
