import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// ADHD-Friendly Login Screen with multi-language support
/// Clean, calm design with clear visual hierarchy and minimal distractions
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
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

  /// Handle login button press
  Future<void> _handleLogin() async {
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
      // Call AuthService to sign in
      await AuthService.instance.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Check if widget is still mounted
      if (!mounted) return;

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
                      // Mascot with welcome message
                      MascotWidget(
                        message: AppStrings.welcomeBack(_currentLocale),
                        size: 140,
                      ),
                      const SizedBox(height: AppTheme.spacingXXLarge),

                      // Title
                      Text(
                        AppStrings.login(_currentLocale),
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),

                      // Subtitle
                      Text(
                        AppStrings.loginSubtitle(_currentLocale),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Email Label
                      Text(
                        AppStrings.email(_currentLocale),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),

                      // Email field
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
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Password Label
                      Text(
                        AppStrings.password(_currentLocale),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.passwordHint(_currentLocale),
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
                        onFieldSubmitted: (_) {
                          if (!_isLoading) {
                            _handleLogin();
                          }
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Login button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                            : Text(AppStrings.login(_currentLocale)),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Forgot password link
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppStrings
                                          .passwordResetComingSoon(
                                              _currentLocale)),
                                      backgroundColor: AppColors.info,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          child: Text(
                            AppStrings.forgotPassword(_currentLocale),
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMedium,
                            ),
                            child: Text(
                              AppStrings.or(_currentLocale),
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXLarge),

                      // Don't have an account link
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
                              AppStrings.dontHaveAccount(_currentLocale),
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
                                      Navigator.of(context)
                                          .pushNamed('/signup');
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSmall,
                                  vertical: 0,
                                ),
                              ),
                              child: Text(
                                AppStrings.signUp(_currentLocale),
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
}
