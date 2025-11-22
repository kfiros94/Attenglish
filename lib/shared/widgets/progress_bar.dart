import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/adhd_theme.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/gamification/services/gamification_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_strings.dart';

/// ADHD-friendly progress bar showing level, XP, and streak
/// Visually engaging with colors and animations
/// Now fetches real data from Firestore
class StudentProgressBar extends StatelessWidget {
  const StudentProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    // Listen to locale changes to rebuild when language changes
    return StreamBuilder<Locale>(
      stream: LocalizationService.instance.localeStream,
      initialData: LocalizationService.instance.currentLocale,
      builder: (context, localeSnapshot) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final xp = userData['xpPoints'] as int? ?? 0;
            final level = userData['currentLevel'] as int? ?? 1;
            final streak = userData['currentStreak'] as int? ?? 0;

            final gamificationService = GamificationService();
            final progress = gamificationService.getProgressToNextLevel(xp);
            final nextLevelXp = gamificationService.getXpForNextLevel(xp);
            final currentLocale = localeSnapshot.data ?? LocalizationService.instance.currentLocale;
            final levelName = gamificationService.getLevelName(
              level,
              useHebrew: currentLocale.languageCode == 'he',
            );

            return _ProgressBarContent(
              level: level,
              levelName: levelName,
              currentXP: xp,
              maxXP: nextLevelXp,
              streakDays: streak,
              progress: progress,
            );
          },
        );
      },
    );
  }
}

/// Internal widget for progress bar content
class _ProgressBarContent extends StatelessWidget {
  final int level;
  final String levelName;
  final int currentXP;
  final int maxXP;
  final int streakDays;
  final double progress;

  const _ProgressBarContent({
    required this.level,
    required this.levelName,
    required this.currentXP,
    required this.maxXP,
    required this.streakDays,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final locale = LocalizationService.instance.currentLocale;

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
                  Text(
                    AppStrings.yourProgress(locale),
                    style: const TextStyle(
                      fontSize: ADHDTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: ADHDTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              _buildStreakBadge(locale),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingMedium),

          // Owl icon + Progress bar section
          Row(
            children: [
              // Owl level icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ADHDTheme.primaryBlue.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  GamificationService.getOwlImageForLevel(level),
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to emoji if image not found
                    return const Center(
                      child: Text(
                        '🦉',
                        style: TextStyle(fontSize: 32),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: ADHDTheme.spacingMedium),

              // Progress bar and XP info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level name and number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              levelName,
                              style: const TextStyle(
                                fontSize: ADHDTheme.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: ADHDTheme.primaryBlue,
                              ),
                            ),
                            Text(
                              '${AppStrings.level(locale)} $level',
                              style: const TextStyle(
                                fontSize: ADHDTheme.fontSizeSmall,
                                color: ADHDTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // XP text
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

                    const SizedBox(height: ADHDTheme.spacingSmall),

                    // Progress bar
                    _buildProgressBar(progress),
                  ],
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
  Widget _buildStreakBadge(Locale locale) {
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
            '$streakDays${AppStrings.dayStreak(locale)}',
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
