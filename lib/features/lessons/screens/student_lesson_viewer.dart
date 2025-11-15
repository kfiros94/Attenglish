import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/adhd_theme.dart';
import '../../../shared/widgets/atti_mascot.dart';
import '../../../shared/widgets/simple_audio_player.dart';
import '../models/lesson_model.dart';
import '../models/activity_model.dart';
import '../services/lesson_service.dart';
import 'student_activity_player_screen.dart';

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
  int _totalPointsEarned = 0;

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

  /// Calculate total points from all activities
  int _getTotalPoints() {
    return _lesson!.activities.fold(0, (sum, activity) => sum + activity.points);
  }

  /// Get activity type label
  String _getActivityTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'true_false':
        return 'True or False';
      case 'drag_drop':
        return 'Drag & Drop';
      default:
        return 'Activity';
    }
  }

  /// Get activity color based on type
  Color _getActivityColor(String type) {
    switch (type) {
      case 'multiple_choice':
        return Colors.blue;
      case 'fill_blank':
        return Colors.green;
      case 'true_false':
        return Colors.orange;
      case 'drag_drop':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Start activities - navigate to Activity Player Screen
  Future<void> _startActivities() async {
    final score = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => StudentActivityPlayerScreen(
          activities: _lesson!.activities,
          lessonTitle: _lesson!.title,
        ),
      ),
    );

    // Show score feedback if activities were completed
    if (score != null && mounted) {
      setState(() {
        _totalPointsEarned = score;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              Text('You earned $score points!'),
            ],
          ),
          backgroundColor: ADHDTheme.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );
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

          // Check if this is an AI-generated lesson with document
          if (_lesson!.sourceDocumentUrl != null && _lesson!.sourceDocumentUrl!.isNotEmpty) ...[
            // AI Generated Badge
            Container(
              padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                border: Border.all(color: Colors.purple.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'AI Generated Lesson',
                        style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This lesson was created from a document uploaded by your teacher.',
                    style: ADHDTheme.studentTextTheme.bodyMedium?.copyWith(
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ADHDTheme.spacingMedium),

            // Document Download Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
              ),
              child: InkWell(
                onTap: () => _downloadDocument(
                  _lesson!.sourceDocumentUrl!,
                  _lesson!.sourceDocumentName ?? 'lesson_document',
                ),
                borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
                  child: Row(
                    children: [
                      // Document icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getDocumentIcon(_lesson!.sourceDocumentType),
                          size: 32,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: ADHDTheme.spacingMedium),

                      // Document info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lesson!.sourceDocumentName ?? 'Lesson Document',
                              style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to open ${_lesson!.sourceDocumentType ?? 'document'}',
                              style: ADHDTheme.studentTextTheme.bodySmall?.copyWith(
                                color: ADHDTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Download icon
                      const Icon(
                        Icons.open_in_new,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: ADHDTheme.spacingMedium),

            // Text preview (if available)
            if (_lesson!.sourceText != null && _lesson!.sourceText!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.preview, size: 18, color: ADHDTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Preview',
                            style: ADHDTheme.studentTextTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _lesson!.sourceText!.length > 300
                            ? '${_lesson!.sourceText!.substring(0, 300)}...'
                            : _lesson!.sourceText!,
                        style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: ADHDTheme.textPrimary,
                        ),
                      ),
                      if (_lesson!.sourceText!.length > 300) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Open the document above to read the full text.',
                                style: ADHDTheme.studentTextTheme.bodySmall?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: ADHDTheme.spacingXLarge),
          ] else ...[
            // Regular lesson - show text content as normal
            if (_lesson!.textContent.isNotEmpty)
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
          ],

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
            _buildActivitiesSection(),
            const SizedBox(height: ADHDTheme.spacingXLarge),
          ],

          // Big completion button (only show if no activities)
          if (_lesson!.activities.isEmpty)
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

  /// Build activities section with preview list
  Widget _buildActivitiesSection() {
    final totalPoints = _getTotalPoints();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Activities header
          Row(
            children: [
              Icon(
                Icons.quiz,
                color: ADHDTheme.accentOrange,
                size: 32,
              ),
              const SizedBox(width: ADHDTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activities',
                      style: ADHDTheme.studentTextTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ADHDTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${_lesson!.activities.length} activities • $totalPoints points',
                      style: ADHDTheme.studentTextTheme.bodyMedium?.copyWith(
                        color: ADHDTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingLarge),

          // Start Activities button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _startActivities,
              style: ElevatedButton.styleFrom(
                backgroundColor: ADHDTheme.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 24),
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
          const SizedBox(height: ADHDTheme.spacingLarge),

          // Activity preview list
          ...List.generate(
            _lesson!.activities.length,
            (index) => _buildActivityPreview(_lesson!.activities[index], index),
          ),
        ],
      ),
    );
  }

  /// Build activity preview tile
  Widget _buildActivityPreview(ActivityModel activity, int index) {
    final color = _getActivityColor(activity.type);
    final label = _getActivityTypeLabel(activity.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: ADHDTheme.spacingMedium),
      child: Container(
        padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ADHDTheme.radiusSmall),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Activity number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ADHDTheme.spacingMedium),

            // Activity info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ADHDTheme.studentTextTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ADHDTheme.textPrimary,
                    ),
                  ),
                  if (activity.question.isNotEmpty)
                    Text(
                      activity.question.length > 50
                          ? '${activity.question.substring(0, 50)}...'
                          : activity.question,
                      style: ADHDTheme.studentTextTheme.bodySmall?.copyWith(
                        color: ADHDTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ADHDTheme.spacingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(ADHDTheme.radiusCircle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.points}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get document icon based on file type
  IconData _getDocumentIcon(String? type) {
    if (type == null) return Icons.insert_drive_file;

    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOCX':
        return Icons.description;
      case 'TXT':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Download/open document
  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      final uri = Uri.parse(url);

      // Determine file type from filename
      final fileType = fileName.split('.').last.toUpperCase();

      // Try to launch the URL
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Opens outside the app
      );

      if (!launched) {
        // Failed to launch - show helpful error
        throw Exception('No app available to open this file type');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Opening $fileName...')),
              ],
            ),
            backgroundColor: ADHDTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Determine file type for better error message
      final fileType = fileName.split('.').last.toUpperCase();

      // Show error dialog with helpful instructions
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Cannot Open Document'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unable to open the $fileType file. This usually happens when:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  const Text('• No compatible app is installed'),
                  const Text('• No browser app is available'),
                  const SizedBox(height: 16),
                  const Text(
                    'To fix this:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Install Chrome or any browser from Play Store'),
                  if (fileType == 'PDF')
                    const Text('2. Install Adobe Acrobat Reader for PDF files'),
                  if (fileType == 'DOCX')
                    const Text('2. Install Microsoft Word or Google Docs for DOCX files'),
                  if (fileType == 'TXT')
                    const Text('2. Install any text editor app for TXT files'),
                  const Text('3. Or try opening on a different device'),
                  const SizedBox(height: 16),
                  Text(
                    'Technical error: $e',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
