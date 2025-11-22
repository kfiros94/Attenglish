import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/adhd_theme.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/constants/app_strings.dart';

/// Streak Calendar Widget
/// Shows visual calendar of last 7 days with activity checkmarks
/// Displays current streak and longest streak
class StreakCalendar extends StatelessWidget {
  const StreakCalendar({super.key});

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
            final currentStreak = userData['currentStreak'] as int? ?? 0;
            final longestStreak = userData['longestStreak'] as int? ?? 0;
            final lastActivityDate = userData['lastActivityDate'] != null
                ? DateTime.parse(userData['lastActivityDate'] as String)
                : null;

            return _StreakCalendarContent(
              currentStreak: currentStreak,
              longestStreak: longestStreak,
              lastActivityDate: lastActivityDate,
            );
          },
        );
      },
    );
  }
}

/// Internal content widget for streak calendar
class _StreakCalendarContent extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  const _StreakCalendarContent({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
  });

  @override
  Widget build(BuildContext context) {
    final locale = LocalizationService.instance.currentLocale;

    return Container(
      padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        border: Border.all(
          color: ADHDTheme.progressEmpty,
          width: 2,
        ),
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
          // Header with fire emoji
          Row(
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(width: ADHDTheme.spacingSmall),
              Text(
                AppStrings.dailyStreak(locale),
                style: const TextStyle(
                  fontSize: ADHDTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: ADHDTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingMedium),

          // Current and longest streak stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakStat(
                label: AppStrings.currentStreak(locale),
                value: currentStreak,
                color: ADHDTheme.accentOrange,
              ),
              Container(
                width: 2,
                height: 40,
                color: ADHDTheme.progressEmpty,
              ),
              _buildStreakStat(
                label: AppStrings.longestStreak(locale),
                value: longestStreak,
                color: ADHDTheme.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: ADHDTheme.spacingLarge),

          // 7-day calendar view
          _build7DayCalendar(locale),
        ],
      ),
    );
  }

  /// Build individual streak stat
  Widget _buildStreakStat({
    required String label,
    required int value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: ADHDTheme.fontSizeSmall,
            color: ADHDTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build 7-day calendar view showing activity
  Widget _build7DayCalendar(Locale locale) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final lastActivityNormalized = lastActivityDate != null
        ? DateTime(
            lastActivityDate!.year,
            lastActivityDate!.month,
            lastActivityDate!.day,
          )
        : null;

    // Calculate which days have activity based on current streak
    final activeDays = <DateTime>{};
    if (lastActivityNormalized != null && currentStreak > 0) {
      // Add days going backwards from last activity date
      for (int i = 0; i < currentStreak; i++) {
        activeDays.add(
          lastActivityNormalized.subtract(Duration(days: i)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.last7Days(locale),
          style: const TextStyle(
            fontSize: ADHDTheme.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: ADHDTheme.textSecondary,
          ),
        ),
        const SizedBox(height: ADHDTheme.spacingSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = todayNormalized.subtract(Duration(days: 6 - index));
            final hasActivity = activeDays.contains(day);
            final isToday = day == todayNormalized;

            return _buildDayCircle(
              day: day,
              hasActivity: hasActivity,
              isToday: isToday,
            );
          }),
        ),
      ],
    );
  }

  /// Build individual day circle
  Widget _buildDayCircle({
    required DateTime day,
    required bool hasActivity,
    required bool isToday,
  }) {
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dayName = dayNames[day.weekday - 1];

    return Column(
      children: [
        // Day name
        Text(
          dayName,
          style: TextStyle(
            fontSize: ADHDTheme.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: isToday ? ADHDTheme.accentOrange : ADHDTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        // Day circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasActivity
                ? ADHDTheme.secondaryGreen.withOpacity(0.2)
                : Colors.grey.shade100,
            border: Border.all(
              color: isToday
                  ? ADHDTheme.accentOrange
                  : hasActivity
                      ? ADHDTheme.secondaryGreen
                      : Colors.grey.shade300,
              width: isToday ? 3 : 2,
            ),
          ),
          child: Center(
            child: hasActivity
                ? const Icon(
                    Icons.check,
                    color: ADHDTheme.secondaryGreen,
                    size: 24,
                  )
                : Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: ADHDTheme.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
