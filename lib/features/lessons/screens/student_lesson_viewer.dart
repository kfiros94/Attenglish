import 'package:flutter/material.dart';
import '../../../core/theme/adhd_theme.dart';
import '../../../shared/widgets/atti_mascot.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';

/// ADHD-friendly lesson viewer for students
/// Large text, clear sections, encouraging feedback
class StudentLessonViewer extends StatefulWidget {
  final String lessonId;

  const StudentLessonViewer({
    super.key,
    required this.lessonId,
  });

  @override
  State<StudentLessonViewer> createState() => _StudentLessonViewerState();
}

class _StudentLessonViewerState extends State<StudentLessonViewer> {
  LessonModel? _lesson;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  /// Load lesson data
  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _lesson = await LessonService.instance.getLesson(widget.lessonId);
      if (_lesson == null) {
        setState(() => _errorMessage = 'Lesson not found');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load lesson: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Mark lesson as complete (with celebration!)
  void _completeLesson() {
    setState(() => _showCelebration = true);

    // Show celebration for 3 seconds then navigate back
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate completion
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ADHDTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: ADHDTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          _lesson?.title ?? 'Lesson',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: ADHDTheme.primaryBlue,
                    strokeWidth: 6,
                  ),
                  const SizedBox(height: ADHDTheme.spacingMedium),
                  Text(
                    'Loading your lesson...',
                    style: ADHDTheme.studentTextTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('😢', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: ADHDTheme.spacingMedium),
                      Text(
                        'Oops!',
                        style: ADHDTheme.studentTextTheme.displaySmall,
                      ),
                      const SizedBox(height: ADHDTheme.spacingSmall),
                      Text(
                        _errorMessage!,
                        style: ADHDTheme.studentTextTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: ADHDTheme.spacingLarge),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ADHDTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: ADHDTheme.spacingLarge,
                            vertical: ADHDTheme.spacingMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _showCelebration
                  ? _buildCelebration()
                  : _buildLessonContent(),
    );
  }

  /// Build celebration screen
  Widget _buildCelebration() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ADHDTheme.successGreen.withOpacity(0.2),
            ADHDTheme.accentOrange.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebration emoji
            const Text(
              '🎉',
              style: TextStyle(fontSize: 100),
            ),
            const SizedBox(height: ADHDTheme.spacingLarge),

            // Congratulations text
            Text(
              'Amazing Work!',
              style: ADHDTheme.studentTextTheme.displayLarge?.copyWith(
                color: ADHDTheme.successGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ADHDTheme.spacingSmall),
            Text(
              'You completed the lesson!',
              style: ADHDTheme.studentTextTheme.headlineMedium,
            ),
            const SizedBox(height: ADHDTheme.spacingLarge),

            // Points earned
            Container(
              padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ADHDTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: ADHDTheme.accentOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: ADHDTheme.spacingSmall),
                  Text(
                    '+50 Points!',
                    style: ADHDTheme.studentTextTheme.headlineLarge?.copyWith(
                      color: ADHDTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ADHDTheme.spacingMedium),

            // Atti mascot
            const AttiMascot(
              message: 'You\'re doing great! Keep it up!',
              size: AttiSize.medium,
              showSpeechBubble: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Build main lesson content
  Widget _buildLessonContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encouraging header with Atti
          Container(
            padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ADHDTheme.primaryBlue.withOpacity(0.1),
                  ADHDTheme.secondaryGreen.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
            ),
            child: Row(
              children: [
                const Text('👋', style: TextStyle(fontSize: 40)),
                const SizedBox(width: ADHDTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to learn?',
                        style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ADHDTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take your time and read carefully!',
                        style: ADHDTheme.studentTextTheme.bodyMedium?.copyWith(
                          color: ADHDTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingXLarge),

          // Lesson info badges
          Wrap(
            spacing: ADHDTheme.spacingSmall,
            runSpacing: ADHDTheme.spacingSmall,
            children: [
              _buildInfoBadge(
                icon: '📊',
                label: _lesson!.difficultyLabel,
                color: _getDifficultyColor(_lesson!.difficulty),
              ),
              if (_lesson!.topic != null)
                _buildInfoBadge(
                  icon: '📚',
                  label: _lesson!.topic!,
                  color: ADHDTheme.primaryBlue,
                ),
              _buildInfoBadge(
                icon: '⏱️',
                label: '5 min',
                color: ADHDTheme.secondaryGreen,
              ),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingXLarge),

          // Description (if available)
          if (_lesson!.description != null && _lesson!.description!.isNotEmpty) ...[
            _buildSectionHeader('📝 What you\'ll learn'),
            const SizedBox(height: ADHDTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
              decoration: BoxDecoration(
                color: ADHDTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                border: Border.all(
                  color: ADHDTheme.accentOrange.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(
                _lesson!.description!,
                style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: ADHDTheme.spacingXLarge),
          ],

          // Main lesson content
          _buildSectionHeader('📖 Lesson'),
          const SizedBox(height: ADHDTheme.spacingMedium),
          Container(
            padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _lesson!.textContent,
              style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                height: 1.8,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingXLarge),

          // Encouraging message from Atti
          Container(
            padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
            decoration: BoxDecoration(
              color: ADHDTheme.secondaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
            ),
            child: Row(
              children: [
                const Text('💪', style: TextStyle(fontSize: 32)),
                const SizedBox(width: ADHDTheme.spacingMedium),
                Expanded(
                  child: Text(
                    'Great job reading! Did you understand everything?',
                    style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ADHDTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingXLarge),

          // Big completion button
          ElevatedButton(
            onPressed: _completeLesson,
            style: ElevatedButton.styleFrom(
              backgroundColor: ADHDTheme.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: ADHDTheme.spacingLarge,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
              ),
              elevation: ADHDTheme.elevationMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 32),
                const SizedBox(width: ADHDTheme.spacingSmall),
                Text(
                  'I Finished Reading! 🎉',
                  style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingLarge),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ADHDTheme.studentTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ADHDTheme.textPrimary,
      ),
    );
  }

  /// Build info badge
  Widget _buildInfoBadge({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ADHDTheme.spacingMedium,
        vertical: ADHDTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ADHDTheme.radiusCircle),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: ADHDTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Get difficulty color
  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return ADHDTheme.successGreen;
      case 2:
        return ADHDTheme.primaryBlue;
      case 3:
        return ADHDTheme.accentOrange;
      case 4:
      case 5:
        return Colors.red;
      default:
        return ADHDTheme.textSecondary;
    }
  }
}
