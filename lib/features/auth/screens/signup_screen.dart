import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// ADHD-Friendly Sign Up Screen with multi-language support
/// Clean, calm design with clear visual hierarchy and step-by-step guidance
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _cityController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'student'; // Default role - app is for students only
  int _selectedGrade = 1; // Default grade for students
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _userNameController.dispose();
    _schoolNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseEnterEmail(_currentLocale);
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.pleaseEnterValidEmail(_currentLocale);
    }
    return null;
  }

  /// Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseEnterPassword(_currentLocale);
    }
    if (value.length < 6) {
      return AppStrings.passwordTooShort(_currentLocale);
    }
    return null;
  }

  /// Validate confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseConfirmPassword(_currentLocale);
    }
    if (value != _passwordController.text) {
      return AppStrings.passwordsDoNotMatch(_currentLocale);
    }
    return null;
  }

  /// Validate required text field
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return AppStrings.pleaseEnter(_currentLocale, fieldName);
    }
    return null;
  }

  /// Handle sign up button press
  Future<void> _handleSignUp() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Create UserModel with form data
      final userData = UserModel(
        id: '', // Will be set by AuthService
        userName: _userNameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        schoolName: _schoolNameController.text.trim(),
        city: _cityController.text.trim(),
        grade: _selectedGrade, // Include grade for students
        createdAt: DateTime.now(),
      );

      // Call AuthService to sign up
      await AuthService.instance.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        userData,
      );

      // Check if widget is still mounted
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.accountCreatedSuccess(_currentLocale)),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to home screen
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      // Check if widget is still mounted
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: AppStrings.goBack(_currentLocale),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo with welcome message
                      MascotWidget(
                        message: AppStrings.letsGetStarted(_currentLocale),
                        size: 220,
                        useLogo: true,
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Title
                      Text(
                        AppStrings.createAccount(_currentLocale),
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),

                      // Subtitle
                      Text(
                        AppStrings.signupSubtitle(_currentLocale),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Section: Personal Information
                      _buildSectionHeader(
                        AppStrings.personalInformation(_currentLocale),
                        Icons.person,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // Full Name field
                      _buildFieldLabel(AppStrings.fullName(_currentLocale)),
                      TextFormField(
                        controller: _fullNameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.fullNameHint(_currentLocale),
                          prefixIcon: const Icon(
                            Icons.person_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) => _validateRequired(
                          value,
                          AppStrings.fullName(_currentLocale).toLowerCase(),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // Username field
                      _buildFieldLabel(AppStrings.username(_currentLocale)),
                      TextFormField(
                        controller: _userNameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.usernameHint(_currentLocale),
                          prefixIcon: const Icon(
                            Icons.account_circle_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) => _validateRequired(
                          value,
                          AppStrings.username(_currentLocale).toLowerCase(),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Section: Account Information
                      _buildSectionHeader(
                        AppStrings.accountInformation(_currentLocale),
                        Icons.email,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // Email field
                      _buildFieldLabel(AppStrings.email(_currentLocale)),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.emailHint(_currentLocale),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: _validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // Password field
                      _buildFieldLabel(AppStrings.password(_currentLocale)),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.passwordRequirement(_currentLocale),
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: AppColors.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                            tooltip: _obscurePassword
                                ? AppStrings.showPassword(_currentLocale)
                                : AppStrings.hidePassword(_currentLocale),
                          ),
                        ),
                        validator: _validatePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // Confirm Password field
                      _buildFieldLabel(AppStrings.confirmPassword(_currentLocale)),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.confirmPasswordHint(_currentLocale),
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: AppColors.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                            tooltip: _obscureConfirmPassword
                                ? AppStrings.showPassword(_currentLocale)
                                : AppStrings.hidePassword(_currentLocale),
                          ),
                        ),
                        validator: _validateConfirmPassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Section: School Information
                      _buildSectionHeader(
                        AppStrings.schoolInformation(_currentLocale),
                        Icons.school,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // School Name field
                      _buildFieldLabel(AppStrings.schoolName(_currentLocale)),
                      TextFormField(
                        controller: _schoolNameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.schoolNameHint(_currentLocale),
                          prefixIcon: const Icon(
                            Icons.school_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) => _validateRequired(
                          value,
                          AppStrings.schoolName(_currentLocale).toLowerCase(),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // Grade dropdown
                      _buildFieldLabel(_currentLocale.languageCode == 'he' ? 'כיתה' : 'Grade'),
                      DropdownButtonFormField<int>(
                        value: _selectedGrade,
                        decoration: InputDecoration(
                          hintText: _currentLocale.languageCode == 'he' ? 'בחר כיתה' : 'Select Grade',
                          prefixIcon: const Icon(
                            Icons.school_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        items: List.generate(6, (index) {
                          final grade = index + 1;
                          return DropdownMenuItem(
                            value: grade,
                            child: Text(
                              _currentLocale.languageCode == 'he' ? 'כיתה $grade' : 'Grade $grade',
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeMedium,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedGrade = value;
                                  });
                                }
                              },
                        validator: (value) {
                          if (value == null) {
                            return _currentLocale.languageCode == 'he'
                                ? 'נא לבחור כיתה'
                                : 'Please select a grade';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // City field
                      _buildFieldLabel(AppStrings.city(_currentLocale)),
                      TextFormField(
                        controller: _cityController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.cityHint(_currentLocale),
                          prefixIcon: const Icon(
                            Icons.location_city_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) => _validateRequired(
                          value,
                          AppStrings.city(_currentLocale).toLowerCase(),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) {
                          if (!_isLoading) {
                            _handleSignUp();
                          }
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Sign Up button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.textOnPrimary,
                          disabledBackgroundColor: AppColors.border,
                          disabledForegroundColor: AppColors.textTertiary,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnPrimary,
                                  ),
                                ),
                              )
                            : Text(AppStrings.createAccount(_currentLocale)),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Already have an account link
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.alreadyHaveAccount(_currentLocale),
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeMedium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSmall,
                                  vertical: 0,
                                ),
                              ),
                              child: Text(
                                AppStrings.login(_currentLocale),
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Language toggle button (top-right)
            const PositionedLanguageToggle(
              top: 16,
              right: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: AppTheme.spacingSmall),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build field label
  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
