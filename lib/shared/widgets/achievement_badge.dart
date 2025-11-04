import 'package:flutter/material.dart';
import '../../core/theme/adhd_theme.dart';

/// Achievement badge widget for gamification
/// Shows earned and locked badges
class AchievementBadge extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isLocked;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.emoji,
    required this.title,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLocked
                  ? ADHDTheme.badgeLocked.withOpacity(0.2)
                  : ADHDTheme.badgeGold.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isLocked ? ADHDTheme.badgeLocked : ADHDTheme.badgeGold,
                width: 3,
              ),
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: ADHDTheme.badgeGold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                isLocked ? '🔒' : emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: ADHDTheme.spacingSmall),

          // Badge title
          Text(
            title,
            style: TextStyle(
              fontSize: ADHDTheme.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: isLocked
                  ? ADHDTheme.textSecondary
                  : ADHDTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Achievement section with multiple badges
class AchievementSection extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementSection({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: ADHDTheme.spacingSmall),
              const Text(
                'Your Achievements',
                style: TextStyle(
                  fontSize: ADHDTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: ADHDTheme.textPrimary,
                ),
              ),
              const Spacer(),
              _buildEarnedCount(),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingMedium),

          // Badges grid
          Wrap(
            spacing: ADHDTheme.spacingMedium,
            runSpacing: ADHDTheme.spacingMedium,
            children: achievements.map((achievement) {
              return SizedBox(
                width: 80,
                child: AchievementBadge(
                  emoji: achievement.emoji,
                  title: achievement.title,
                  isLocked: !achievement.isEarned,
                  onTap: () => _showAchievementDetails(context, achievement),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build earned count badge
  Widget _buildEarnedCount() {
    final earnedCount = achievements.where((a) => a.isEarned).length;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ADHDTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: ADHDTheme.successGreen,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusSmall),
      ),
      child: Text(
        '$earnedCount/${achievements.length}',
        style: const TextStyle(
          fontSize: ADHDTheme.fontSizeSmall,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Show achievement details dialog
  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Text(
              achievement.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: ADHDTheme.spacingSmall),
            Expanded(
              child: Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: ADHDTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: ADHDTheme.fontSizeMedium,
                height: 1.5,
              ),
            ),
            if (!achievement.isEarned) ...[
              const SizedBox(height: ADHDTheme.spacingMedium),
              Container(
                padding: const EdgeInsets.all(ADHDTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: ADHDTheme.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ADHDTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: ADHDTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        'Keep going to unlock this badge!',
                        style: const TextStyle(
                          fontSize: ADHDTheme.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                          color: ADHDTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: ADHDTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Achievement model
class Achievement {
  final String emoji;
  final String title;
  final String description;
  final bool isEarned;

  const Achievement({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isEarned,
  });

  /// Sample achievements for testing
  static List<Achievement> getSampleAchievements() {
    return [
      const Achievement(
        emoji: '🎖️',
        title: 'First Lesson',
        description: 'Complete your first English lesson!',
        isEarned: true,
      ),
      const Achievement(
        emoji: '🔥',
        title: '3-Day Streak',
        description: 'Practice for 3 days in a row!',
        isEarned: true,
      ),
      const Achievement(
        emoji: '⭐',
        title: '100 Points',
        description: 'Earn your first 100 points!',
        isEarned: true,
      ),
      const Achievement(
        emoji: '🏆',
        title: 'Level 5',
        description: 'Reach Level 5 in your learning journey!',
        isEarned: false,
      ),
      const Achievement(
        emoji: '🎯',
        title: 'Perfect Score',
        description: 'Get 100% on a lesson!',
        isEarned: false,
      ),
    ];
  }
}
