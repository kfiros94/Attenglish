import 'package:flutter/material.dart';
import '../models/tutorial_step.dart';
import '../services/tutorial_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Tutorial dialog that displays steps with navigation
class TutorialDialog extends StatefulWidget {
  final List<TutorialStep> steps;
  final String userRole;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialDialog({
    super.key,
    required this.steps,
    required this.userRole,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _currentStepIndex = 0;

  TutorialStep get _currentStep => widget.steps[_currentStepIndex];
  bool get _isFirstStep => _currentStepIndex == 0;
  bool get _isLastStep => _currentStepIndex == widget.steps.length - 1;

  void _nextStep() async {
    if (_isLastStep) {
      await TutorialService.instance.completeTutorial(widget.userRole);
      widget.onComplete();
    } else {
      setState(() {
        _currentStepIndex++;
      });
      _currentStep.onStepShow?.call();
    }
  }

  void _previousStep() {
    if (!_isFirstStep) {
      setState(() {
        _currentStepIndex--;
      });
      _currentStep.onStepShow?.call();
    }
  }

  void _skip() async {
    await TutorialService.instance.completeTutorial(widget.userRole);
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;
    final step = _currentStep;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            if (step.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  step.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                step.getTitle(isRTL),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step.getMessage(isRTL),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.steps.length,
              (index) => Container(
                width: index == _currentStepIndex ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == _currentStepIndex
                      ? AppColors.primary
                      : index < _currentStepIndex
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Skip button
        if (!_isLastStep)
          TextButton(
            onPressed: _skip,
            child: Text(
              isRTL ? 'דלג' : 'Skip',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),

        // Back button
        if (!_isFirstStep)
          TextButton(
            onPressed: _previousStep,
            child: Text(
              isRTL ? 'הקודם' : 'Back',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),

        // Next/Finish button
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isLastStep
                ? (isRTL ? 'סיום' : 'Finish')
                : (isRTL ? 'הבא' : 'Next'),
          ),
        ),
      ],
    );
  }
}

/// Controller to manage tutorial display using showDialog
class TutorialController {
  bool _isShowing = false;

  /// Show the tutorial dialog
  void show({
    required BuildContext context,
    required List<TutorialStep> steps,
    required String userRole,
    required VoidCallback onComplete,
    VoidCallback? onSkip,
  }) {
    if (_isShowing) return;
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (dialogContext) => TutorialDialog(
        steps: steps,
        userRole: userRole,
        onComplete: () {
          Navigator.of(dialogContext).pop();
          _isShowing = false;
          onComplete();
        },
        onSkip: () {
          Navigator.of(dialogContext).pop();
          _isShowing = false;
          if (onSkip != null) {
            onSkip();
          } else {
            onComplete();
          }
        },
      ),
    ).then((_) {
      _isShowing = false;
    });
  }

  /// Hide the tutorial (for cleanup)
  void hide() {
    _isShowing = false;
  }

  /// Check if tutorial is currently showing
  bool get isShowing => _isShowing;
}
