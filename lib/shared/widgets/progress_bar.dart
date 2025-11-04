import 'package:flutter/material.dart';
import '../../core/theme/adhd_theme.dart';

/// ADHD-friendly progress bar showing level, XP, and streak
/// Visually engaging with colors and animations
class StudentProgressBar extends StatelessWidget {
  final int level;
  final int currentXP;
  final int maxXP;
  final int streakDays;

  const StudentProgressBar({
    super.key,
    required this.level,
    required this.currentXP,
    required this.maxXP,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXP > 0 ? currentXP / maxXP : 0.0;

    return Container(
      padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
      decoration: ADHDTheme.progressCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Title and Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '📊',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: ADHDTheme.spacingSmall),
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: ADHDTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: ADHDTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              _buildStreakBadge(),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingMedium),

          // Progress bar
          _buildProgressBar(progress),
          const SizedBox(height: ADHDTheme.spacingSmall),

          // Level and XP info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: ADHDTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: ADHDTheme.primaryBlue,
                ),
              ),
              Text(
                '$currentXP / $maxXP XP',
                style: const TextStyle(
                  fontSize: ADHDTheme.fontSizeSmall,
                  color: ADHDTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build animated progress bar
  Widget _buildProgressBar(double progress) {
    return Stack(
      children: [
        // Background (empty progress)
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: ADHDTheme.progressEmpty,
            borderRadius: BorderRadius.circular(ADHDTheme.radiusCircle),
          ),
        ),

        // Foreground (filled progress)
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ADHDTheme.primaryBlue,
                  ADHDTheme.secondaryGreen,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(ADHDTheme.radiusCircle),
              boxShadow: [
                BoxShadow(
                  color: ADHDTheme.primaryBlue.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),

        // Percentage text overlay
        Container(
          height: 20,
          alignment: Alignment.center,
          child: Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build streak badge
  Widget _buildStreakBadge() {
    final emoji = ADHDTheme.getStreakEmoji(streakDays);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ADHDTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: ADHDTheme.accentOrange,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: ADHDTheme.accentOrange.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            '$streakDays-day streak!',
            style: const TextStyle(
              fontSize: ADHDTheme.fontSizeSmall,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
