import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// Special signup screen for creating the first admin account
/// This should only be used for initial setup
class AdminSignUpScreen extends StatefulWidget {
  const AdminSignUpScreen({super.key});

  @override
  State<AdminSignUpScreen> createState() => _AdminSignUpScreenState();
}

class _AdminSignUpScreenState extends State<AdminSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
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

  /// Handle admin signup
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = UserModel(
        id: '', // Will be set by Firebase
        userName: _userNameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        role: 'admin', // Admin role
        schoolName: _schoolNameController.text.trim(),
        city: _cityController.text.trim(),
        createdAt: DateTime.now(),
      );

      await AuthService.instance.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        userData,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.accountCreatedSuccess(_currentLocale)),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: AppStrings.goBack(_currentLocale),
        ),
        actions: const [
          LanguageToggle(size: 36),
          SizedBox(width: AppTheme.spacingMedium),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mascot
                MascotWidget(
                  message: AppStrings.adminSignupMessage(_currentLocale),
                  size: 100,
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Title
                Text(
                  AppStrings.createAdminAccount(_currentLocale),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Personal Information Section
                Text(
                  AppStrings.personalInformation(_currentLocale),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.fullName(_currentLocale),
                    hintText: AppStrings.fullNameHint(_currentLocale),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.pleaseEnter(
                          _currentLocale, AppStrings.fullName(_currentLocale));
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Username
                TextFormField(
                  controller: _userNameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.username(_currentLocale),
                    hintText: AppStrings.usernameHint(_currentLocale),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.pleaseEnter(
                          _currentLocale, AppStrings.username(_currentLocale));
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Account Information Section
                Text(
                  AppStrings.accountInformation(_currentLocale),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppStrings.email(_currentLocale),
                    hintText: AppStrings.emailHint(_currentLocale),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.pleaseEnterEmail(_currentLocale);
                    }
                    if (!value.contains('@')) {
                      return AppStrings.pleaseEnterValidEmail(_currentLocale);
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
                    labelText: AppStrings.password(_currentLocale),
                    hintText: AppStrings.passwordHint(_currentLocale),
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
                      tooltip: _obscurePassword
                          ? AppStrings.showPassword(_currentLocale)
                          : AppStrings.hidePassword(_currentLocale),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.pleaseEnterPassword(_currentLocale);
                    }
                    if (value.length < 6) {
                      return AppStrings.passwordTooShort(_currentLocale);
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
                    labelText: AppStrings.confirmPassword(_currentLocale),
                    hintText: AppStrings.confirmPasswordHint(_currentLocale),
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
                      tooltip: _obscureConfirmPassword
                          ? AppStrings.showPassword(_currentLocale)
                          : AppStrings.hidePassword(_currentLocale),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.pleaseConfirmPassword(_currentLocale);
                    }
                    if (value != _passwordController.text) {
                      return AppStrings.passwordsDoNotMatch(_currentLocale);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // School Information Section
                Text(
                  AppStrings.schoolInformation(_currentLocale),
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // School Name
                TextFormField(
                  controller: _schoolNameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.schoolName(_currentLocale),
                    hintText: AppStrings.schoolNameHint(_currentLocale),
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.pleaseEnter(
                          _currentLocale, AppStrings.schoolName(_currentLocale));
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: AppStrings.city(_currentLocale),
                    hintText: AppStrings.cityHint(_currentLocale),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.pleaseEnter(
                          _currentLocale, AppStrings.city(_currentLocale));
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingXLarge),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMedium,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : Text(
                          AppStrings.createAdminAccount(_currentLocale),
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount(_currentLocale),
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        AppStrings.login(_currentLocale),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
