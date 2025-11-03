import 'package:flutter/material.dart';
import '../../core/services/localization_service.dart';
import '../../core/theme/app_theme.dart';

/// Language toggle button with PNG flag images
/// Switches between English (UK flag) and Hebrew (Israel flag)
class LanguageToggle extends StatefulWidget {
  final double size;

  const LanguageToggle({
    super.key,
    this.size = 40,
  });

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  Locale _currentLocale = LocalizationService.instance.currentLocale;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    // Animate
    await _animationController.forward();
    await _animationController.reverse();

    // Toggle locale
    await LocalizationService.instance.toggleLocale();
  }

  String get _currentFlagImage {
    return _currentLocale.languageCode == 'en'
        ? 'assets/images/flags/uk.png'
        : 'assets/images/flags/israel.png';
  }

  String get _nextLanguageName {
    return _currentLocale.languageCode == 'en' ? 'עברית' : 'English';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _nextLanguageName,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleToggle,
              customBorder: const CircleBorder(),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      _currentFlagImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to emoji if image not found
                        return Center(
                          child: Text(
                            _currentLocale.languageCode == 'en' ? '🇬🇧' : '🇮🇱',
                            style: TextStyle(
                              fontSize: widget.size * 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Positioned language toggle for absolute positioning
class PositionedLanguageToggle extends StatelessWidget {
  final double? top;
  final double? right;
  final double? left;
  final double size;

  const PositionedLanguageToggle({
    super.key,
    this.top = 16,
    this.right = 16,
    this.left,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      child: LanguageToggle(size: size),
    );
  }
}
