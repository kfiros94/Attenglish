import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../widgets/activities/multiple_choice_widget.dart';
import '../widgets/activities/fill_blank_widget.dart';
import '../widgets/activities/true_false_widget.dart';
import '../widgets/activities/drag_drop_widget.dart';
import '../widgets/activities/image_description_widget.dart';
import '../widgets/activities/cloze_widget.dart';
import '../widgets/activities/open_ended_widget.dart';
import '../../gamification/services/gamification_service.dart';
import '../../auth/services/auth_service.dart';
import '../../student_progress/services/progress_service.dart';

/// Activity Player Screen for Students
///
/// Shows activities one at a time with progress tracking.
/// Students complete each activity and see their score build up.
class StudentActivityPlayerScreen extends StatefulWidget {
  final List<ActivityModel> activities;
  final String lessonTitle;
  final String lessonId;

  const StudentActivityPlayerScreen({
    super.key,
    required this.activities,
    required this.lessonTitle,
    required this.lessonId,
  });

  @override
  State<StudentActivityPlayerScreen> createState() =>
      _StudentActivityPlayerScreenState();
}

class _StudentActivityPlayerScreenState
    extends State<StudentActivityPlayerScreen> {
  int _currentActivityIndex = 0;
  int _totalScore = 0;
  int _totalXpEarned = 0;
  late List<bool> _completedActivities;
  final _gamificationService = GamificationService();
  final _progressService = ProgressService();
  bool _isFirstActivityOfDay = true;
  bool _waitingForNext = false; // For AI-evaluated activities that need manual "Next"

  /// Activity types that require manual "Next" button (AI-evaluated with feedback)
  static const _manualNextActivityTypes = {
    'image_description',
    'cloze',
    'open_ended',
  };

  @override
  void initState() {
    super.initState();
    _completedActivities = List.filled(widget.activities.length, false);
    _checkAndUpdateStreak();
  }

  /// Check and update daily streak on first activity
  Future<void> _checkAndUpdateStreak() async {
    if (_isFirstActivityOfDay) {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser != null) {
        try {
          final streakResult =
              await _gamificationService.updateDailyStreak(currentUser.uid);
          if (mounted && streakResult['earnedStreakBonus'] == true) {
            _showStreakBonusSnackbar(streakResult);
          }
          _isFirstActivityOfDay = false;
        } catch (e) {
          print('Error updating streak: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_totalScore pts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentActivityIndex + 1) / widget.activities.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),

          // Progress text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity ${_currentActivityIndex + 1} of ${widget.activities.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_totalScore points',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Current activity widget
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildCurrentActivity(),
            ),
          ),

          // Next button for AI-evaluated activities
          if (_waitingForNext)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _goToNextActivity,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      _currentActivityIndex >= widget.activities.length - 1
                          ? 'Finish Lesson'
                          : 'Next Activity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentActivity() {
    final activity = widget.activities[_currentActivityIndex];

    switch (activity.type) {
      case 'multiple_choice':
        return MultipleChoiceWidget(
          key: ValueKey('mc_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'fill_blank':
        return FillBlankWidget(
          key: ValueKey('fb_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'true_false':
        return TrueFalseWidget(
          key: ValueKey('tf_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'image_description':
        return ImageDescriptionWidget(
          key: ValueKey('id_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'drag_drop':
        return DragDropWidget(
          key: ValueKey('dd_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'cloze':
        return ClozeWidget(
          key: ValueKey('cloze_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      case 'open_ended':
        return OpenEndedWidget(
          key: ValueKey('oe_$_currentActivityIndex'),
          activity: activity,
          onAnswered: _onActivityAnswered,
        );

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Unknown activity type: ${activity.type}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        );
    }
  }

  void _onActivityAnswered(bool isCorrect, int points) async {
    final currentActivity = widget.activities[_currentActivityIndex];
    final requiresManualNext = _manualNextActivityTypes.contains(currentActivity.type);

    setState(() {
      // Mark as completed
      _completedActivities[_currentActivityIndex] = true;

      // Add points only if correct
      if (isCorrect) {
        _totalScore += points;
      }

      // For AI-evaluated activities, wait for user to click "Next"
      if (requiresManualNext) {
        _waitingForNext = true;
      }
    });

    // Award XP for activity completion
    if (isCorrect) {
      await _awardXpForActivity(isCorrect);
    }

    // Check if last activity
    if (_currentActivityIndex >= widget.activities.length - 1) {
      // Award lesson completion bonus XP
      await _awardLessonCompletionXp();
      // Show completion dialog
      _showCompletionDialog();
    } else if (!requiresManualNext) {
      // Auto-advance only for non-AI-evaluated activities
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentActivityIndex++;
          });
        }
      });
    }
    // For AI-evaluated activities, user must click "Next" button
  }

  /// Moves to next activity (called when user clicks "Next" button)
  void _goToNextActivity() {
    if (_currentActivityIndex < widget.activities.length - 1) {
      setState(() {
        _waitingForNext = false;
        _currentActivityIndex++;
      });
    } else {
      // Last activity - show completion
      _showCompletionDialog();
    }
  }

  /// Award XP for completing an activity
  Future<void> _awardXpForActivity(bool isPerfect) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    try {
      final activity = widget.activities[_currentActivityIndex];
      final result = await _gamificationService.awardXpForActivityCompletion(
        userId: currentUser.uid,
        activityType: activity.type,
        isPerfect: isPerfect,
      );

      setState(() {
        _totalXpEarned += result['xpEarned'] as int;
      });

      // Show XP earned
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.yellow),
                const SizedBox(width: 8),
                Text('+${result['xpEarned']} XP'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Show level up dialog if leveled up
        if (result['didLevelUp'] == true) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _showLevelUpDialog(result);
          }
        }
      }
    } catch (e) {
      print('Error awarding XP: $e');
    }
  }

  /// Award bonus XP for completing entire lesson (only first time)
  Future<void> _awardLessonCompletionXp() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Save lesson completion with score for progress tracking
      await _saveLessonCompletion();

      // Use completeLessonWithReward to check if already completed
      final result = await _gamificationService.completeLessonWithReward(
        userId: currentUser.uid,
        lessonId: widget.lessonId,
        activitiesCompleted: widget.activities.length,
      );

      final alreadyCompleted = result['alreadyCompleted'] as bool;
      final xpEarned = result['xpEarned'] as int;

      setState(() {
        _totalXpEarned += xpEarned;
      });

      // Show lesson completion XP bonus OR already completed message
      if (mounted) {
        if (alreadyCompleted) {
          // Show message that lesson was already completed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Lesson already completed - no XP earned this time'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Show XP earned message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.yellow),
                  const SizedBox(width: 8),
                  Text('Lesson Complete! +$xpEarned XP'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );

          // Show level up dialog if leveled up
          if (result['didLevelUp'] == true) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              _showLevelUpDialog(result);
            }
          }
        }
      }
    } catch (e) {
      print('Error awarding lesson completion XP: $e');
    }
  }

  /// Save lesson completion data for progress tracking
  Future<void> _saveLessonCompletion() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Get user data to find classId
      final userData = await AuthService.instance.getUserData(currentUser.uid);
      final classId = userData?.classId;

      if (classId == null || classId.isEmpty) {
        print('Student has no classId, skipping progress save');
        return;
      }

      // Calculate max possible score from all activities
      final maxScore = widget.activities.fold<int>(
        0,
        (sum, activity) => sum + activity.points,
      );

      // Save the lesson completion
      await _progressService.saveLessonCompletion(
        lessonId: widget.lessonId,
        lessonTitle: widget.lessonTitle,
        studentId: currentUser.uid,
        classId: classId,
        score: _totalScore,
        maxScore: maxScore,
      );

      print('Saved lesson completion: $_totalScore / $maxScore');
    } catch (e) {
      print('Error saving lesson completion: $e');
    }
  }

  void _onBackPressed() {
    // If activities are not completed, show confirmation
    if (_completedActivities.any((completed) => !completed)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave Activity?'),
          content: const Text(
            'You haven\'t completed all activities yet. Your progress will be lost. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context, _totalScore);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber.shade700, size: 32),
            const SizedBox(width: 8),
            const Text('Great Job!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              'You completed all activities!',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Score',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalScore',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Show total XP earned
            if (_totalXpEarned > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '+$_totalXpEarned XP Earned!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Activities: ${widget.activities.length}/${widget.activities.length}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Just close the dialog, stay on current screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Show level up celebration dialog
  void _showLevelUpDialog(Map<String, dynamic> levelUpInfo) {
    final newLevel = levelUpInfo['newLevel'] as int;
    final levelName = levelUpInfo['levelName'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, color: Colors.orange, size: 32),
            const SizedBox(width: 8),
            const Text(
              'Level Up!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated owl icon with scale effect
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade50,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      GamificationService.getOwlImageForLevel(newLevel),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to emoji if image not found
                        return const Center(
                          child: Text(
                            '🦉',
                            style: TextStyle(fontSize: 60),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'You are now a',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              levelName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Level $newLevel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Awesome! 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show streak bonus notification
  void _showStreakBonusSnackbar(Map<String, dynamic> streakResult) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              '🔥 ${streakResult['currentStreak']} Day Streak! +${streakResult['streakBonusXp']} XP',
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
