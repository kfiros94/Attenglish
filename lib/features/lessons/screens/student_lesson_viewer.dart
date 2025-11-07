import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/adhd_theme.dart';
import '../../../shared/widgets/atti_mascot.dart';
import '../../../shared/widgets/simple_audio_player.dart';
import '../models/lesson_model.dart';
import '../models/activity_model.dart';
import '../services/lesson_service.dart';
import '../widgets/activities/activity_widget.dart';

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

  // Activity navigation state
  int _currentActivityIndex = 0;
  bool _hasStartedActivities = false;
  int _totalPointsEarned = 0;
  final Map<int, bool> _activityAnswered = {}; // Track which activities have been answered

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

  /// Start activities
  void _startActivities() {
    setState(() {
      _hasStartedActivities = true;
    });
  }

  /// Handle activity answered
  void _onActivityAnswered(bool isCorrect, int points) {
    setState(() {
      _activityAnswered[_currentActivityIndex] = true;
      if (isCorrect) {
        _totalPointsEarned += points;
      }
    });
  }

  /// Go to next activity
  void _nextActivity() {
    if (_currentActivityIndex < _lesson!.activities.length - 1) {
      setState(() {
        _currentActivityIndex++;
      });
    } else {
      // All activities completed
      _completeLesson();
    }
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
                    '+$_totalPointsEarned Points!',
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

          // Audio player (if available)
          if (_lesson!.audioUrl != null && _lesson!.audioUrl!.isNotEmpty) ...[
            _buildSectionHeader('🎧 Listen to the lesson'),
            const SizedBox(height: ADHDTheme.spacingMedium),

            // Encouraging message
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
                border: Border.all(
                  color: ADHDTheme.primaryBlue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Text('🎧', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: ADHDTheme.spacingMedium),
                  Expanded(
                    child: Text(
                      'Listen carefully! You can pause and replay anytime.',
                      style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ADHDTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ADHDTheme.spacingMedium),

            // Audio player
            SimpleAudioPlayer(
              audioUrl: _lesson!.audioUrl!,
              primaryColor: ADHDTheme.primaryBlue,
              backgroundColor: Colors.white,
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

          // Images gallery (if available)
          if (_lesson!.imageUrls.isNotEmpty) ...[
            _buildSectionHeader('🖼️ Lesson images'),
            const SizedBox(height: ADHDTheme.spacingMedium),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: ADHDTheme.spacingMedium,
                mainAxisSpacing: ADHDTheme.spacingMedium,
              ),
              itemCount: _lesson!.imageUrls.length,
              itemBuilder: (context, index) {
                return _buildImageCard(_lesson!.imageUrls[index]);
              },
            ),
            const SizedBox(height: ADHDTheme.spacingXLarge),
          ],

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

          // Activities Section (if available)
          if (_lesson!.activities.isNotEmpty) ...[
            if (!_hasStartedActivities)
              _buildActivitiesIntro()
            else
              _buildActivitySection(),
            const SizedBox(height: ADHDTheme.spacingXLarge),
          ],

          // Big completion button (only show if no activities or all completed)
          if (_lesson!.activities.isEmpty ||
              (_hasStartedActivities &&
                  _currentActivityIndex >= _lesson!.activities.length - 1 &&
                  _activityAnswered[_currentActivityIndex] == true))
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

  /// Build image card with tap to view full size
  Widget _buildImageCard(String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Show full-size image in dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black87,
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.9,
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: ADHDTheme.primaryBlue,
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('Full-size image error: $error');
                          print('URL: $url');
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.white, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
          border: Border.all(
            color: ADHDTheme.primaryBlue.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium - 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: ADHDTheme.primaryBlue.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ADHDTheme.primaryBlue,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  print('Image thumbnail error for URL: $url');
                  print('Error: $error');
                  return Container(
                    color: Colors.red.withOpacity(0.1),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Tap to expand overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build activities intro section
  Widget _buildActivitiesIntro() {
    return Container(
      padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ADHDTheme.accentOrange.withOpacity(0.2),
            ADHDTheme.primaryBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        border: Border.all(
          color: ADHDTheme.accentOrange.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 40)),
              const SizedBox(width: ADHDTheme.spacingSmall),
              Text(
                'Practice Time!',
                style: ADHDTheme.studentTextTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ADHDTheme.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingMedium),

          // Atti message
          Row(
            children: [
              const Text('👋', style: TextStyle(fontSize: 32)),
              const SizedBox(width: ADHDTheme.spacingSmall),
              Expanded(
                child: Text(
                  '"Let\'s practice what you learned!"',
                  style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingMedium),

          // Activity count
          Container(
            padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ADHDTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports, color: ADHDTheme.primaryBlue),
                const SizedBox(width: ADHDTheme.spacingSmall),
                Text(
                  '${_lesson!.activities.length} activities to complete',
                  style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingLarge),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startActivities,
              style: ElevatedButton.styleFrom(
                backgroundColor: ADHDTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: ADHDTheme.spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 28),
                  const SizedBox(width: ADHDTheme.spacingSmall),
                  Text(
                    'Start Activities',
                    style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build activity section with navigation
  Widget _buildActivitySection() {
    final activity = _lesson!.activities[_currentActivityIndex];
    final hasAnswered = _activityAnswered[_currentActivityIndex] ?? false;
    final isLastActivity = _currentActivityIndex >= _lesson!.activities.length - 1;

    return Container(
      padding: const EdgeInsets.all(ADHDTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: ADHDTheme.accentOrange.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 32)),
              const SizedBox(width: ADHDTheme.spacingSmall),
              Text(
                'Practice Time!',
                style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ADHDTheme.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingSmall),

          // Progress text
          Text(
            'Activity ${_currentActivityIndex + 1} of ${_lesson!.activities.length}',
            style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
              color: ADHDTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ADHDTheme.spacingSmall),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _lesson!.activities.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index <= _currentActivityIndex
                      ? ADHDTheme.accentOrange
                      : ADHDTheme.textSecondary.withOpacity(0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingLarge),

          // Activity widget
          ActivityWidget(
            key: ValueKey(_currentActivityIndex), // Force widget to rebuild when activity changes
            activity: activity,
            onAnswered: _onActivityAnswered,
          ),

          // Next button (only show after answering)
          if (hasAnswered) ...[
            const SizedBox(height: ADHDTheme.spacingLarge),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nextActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastActivity
                      ? ADHDTheme.successGreen
                      : ADHDTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastActivity ? 'Finish Activities! 🎉' : 'Next Activity',
                      style: ADHDTheme.studentTextTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isLastActivity) ...[
                      const SizedBox(width: ADHDTheme.spacingSmall),
                      const Icon(Icons.arrow_forward, size: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
