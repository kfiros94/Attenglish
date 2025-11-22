import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';

/// Gamification Service
/// Handles XP points, leveling system, and daily streaks for students
class GamificationService {
  // XP values for different activities
  static const int XP_MULTIPLE_CHOICE = 10;
  static const int XP_FILL_BLANK = 10;
  static const int XP_TRUE_FALSE = 5;
  static const int XP_DRAG_DROP = 15;
  static const int XP_LESSON_COMPLETE = 50;
  static const int XP_DAILY_STREAK = 20;
  static const int XP_PERFECT_SCORE = 25;

  // Level tier definitions (owl progression)
  static const Map<int, Map<String, dynamic>> LEVEL_TIERS = {
    1: {'nameEn': 'Hatchling', 'nameHe': 'גוזל', 'maxXp': 250},
    2: {'nameEn': 'Hatchling', 'nameHe': 'גוזל', 'maxXp': 500},
    3: {'nameEn': 'Fledgling', 'nameHe': 'אפרוח', 'maxXp': 750},
    4: {'nameEn': 'Fledgling', 'nameHe': 'אפרוח', 'maxXp': 1000},
    5: {'nameEn': 'Fledgling', 'nameHe': 'אפרוח', 'maxXp': 1500},
    6: {'nameEn': 'Young Owl', 'nameHe': 'ינשוף צעיר', 'maxXp': 1875},
    7: {'nameEn': 'Young Owl', 'nameHe': 'ינשוף צעיר', 'maxXp': 2250},
    8: {'nameEn': 'Young Owl', 'nameHe': 'ינשוף צעיר', 'maxXp': 2625},
    9: {'nameEn': 'Young Owl', 'nameHe': 'ינשוף צעיר', 'maxXp': 3000},
    10: {'nameEn': 'Wise Owl', 'nameHe': 'ינשוף חכם', 'maxXp': 3400},
    11: {'nameEn': 'Wise Owl', 'nameHe': 'ינשוף חכם', 'maxXp': 3800},
    12: {'nameEn': 'Wise Owl', 'nameHe': 'ינשוף חכם', 'maxXp': 4200},
    13: {'nameEn': 'Wise Owl', 'nameHe': 'ינשוף חכם', 'maxXp': 4600},
    14: {'nameEn': 'Wise Owl', 'nameHe': 'ינשוף חכם', 'maxXp': 5000},
    15: {'nameEn': 'Master Owl', 'nameHe': 'ינשוף מאסטר', 'maxXp': 5600},
    16: {'nameEn': 'Master Owl', 'nameHe': 'ינשוף מאסטר', 'maxXp': 6200},
    17: {'nameEn': 'Master Owl', 'nameHe': 'ינשוף מאסטר', 'maxXp': 6800},
    18: {'nameEn': 'Master Owl', 'nameHe': 'ינשוף מאסטר', 'maxXp': 7400},
    19: {'nameEn': 'Master Owl', 'nameHe': 'ינשוף מאסטר', 'maxXp': 8000},
    20: {'nameEn': 'Legendary Owl', 'nameHe': 'ינשוף אגדי', 'maxXp': 9000},
  };

  /// Calculate XP earned for completing an activity
  int calculateXpForActivity(String activityType, bool isPerfect) {
    int baseXp = 0;

    switch (activityType) {
      case 'multiple_choice':
        baseXp = XP_MULTIPLE_CHOICE;
        break;
      case 'fill_blank':
        baseXp = XP_FILL_BLANK;
        break;
      case 'true_false':
        baseXp = XP_TRUE_FALSE;
        break;
      case 'drag_drop':
        baseXp = XP_DRAG_DROP;
        break;
      default:
        baseXp = 10;
    }

    // Add bonus for perfect score
    if (isPerfect) {
      baseXp += XP_PERFECT_SCORE;
    }

    return baseXp;
  }

  /// Award XP for activity completion and check for level up
  Future<Map<String, dynamic>> awardXpForActivityCompletion({
    required String userId,
    required String activityType,
    required bool isPerfect,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Calculate XP
    final xpEarned = calculateXpForActivity(activityType, isPerfect);

    // Get current user data
    final userDoc = await userRef.get();
    final userData = userDoc.data()!;

    final currentXp = userData['xpPoints'] as int? ?? 0;
    final currentLevel = userData['currentLevel'] as int? ?? 1;
    final newXp = currentXp + xpEarned;

    // Check for level up
    final newLevel = calculateLevelFromXp(newXp);
    final didLevelUp = newLevel > currentLevel;

    // Update user
    await userRef.update({
      'xpPoints': newXp,
      'currentLevel': newLevel,
    });

    return {
      'xpEarned': xpEarned,
      'newXp': newXp,
      'newLevel': newLevel,
      'didLevelUp': didLevelUp,
      'levelName': getLevelName(newLevel),
    };
  }

  /// Award XP for completing an entire lesson
  Future<Map<String, dynamic>> awardXpForLessonCompletion({
    required String userId,
    required int activitiesCompleted,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Bonus XP for completing lesson
    final xpEarned = XP_LESSON_COMPLETE;

    final userDoc = await userRef.get();
    final userData = userDoc.data()!;

    final currentXp = userData['xpPoints'] as int? ?? 0;
    final currentLevel = userData['currentLevel'] as int? ?? 1;
    final newXp = currentXp + xpEarned;

    final newLevel = calculateLevelFromXp(newXp);
    final didLevelUp = newLevel > currentLevel;

    await userRef.update({
      'xpPoints': newXp,
      'currentLevel': newLevel,
    });

    return {
      'xpEarned': xpEarned,
      'newXp': newXp,
      'newLevel': newLevel,
      'didLevelUp': didLevelUp,
      'levelName': getLevelName(newLevel),
    };
  }

  /// Update daily streak when student does activity
  Future<Map<String, dynamic>> updateDailyStreak(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userRef.get();
    final userData = userDoc.data()!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastActivityDate = userData['lastActivityDate'] != null
        ? DateTime.parse(userData['lastActivityDate'] as String)
        : null;

    final lastActivityDay = lastActivityDate != null
        ? DateTime(
            lastActivityDate.year, lastActivityDate.month, lastActivityDate.day)
        : null;

    int currentStreak = userData['currentStreak'] as int? ?? 0;
    int longestStreak = userData['longestStreak'] as int? ?? 0;
    int streakBonusXp = 0;
    bool earnedStreakBonus = false;

    // Check if this is a new day
    if (lastActivityDay == null || today.isAfter(lastActivityDay)) {
      // Check if streak continues (yesterday) or breaks
      if (lastActivityDay != null &&
          today.difference(lastActivityDay).inDays == 1) {
        // Streak continues!
        currentStreak++;
        streakBonusXp = XP_DAILY_STREAK;
        earnedStreakBonus = true;
      } else if (lastActivityDay != null &&
          today.difference(lastActivityDay).inDays > 1) {
        // Streak broken :(
        currentStreak = 1;
      } else {
        // First day
        currentStreak = 1;
      }

      // Update longest streak
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }

      // Update XP if earned streak bonus
      final currentXp = userData['xpPoints'] as int? ?? 0;
      final newXp = currentXp + streakBonusXp;
      final currentLevel = userData['currentLevel'] as int? ?? 1;
      final newLevel = calculateLevelFromXp(newXp);

      // Update user
      await userRef.update({
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': now.toIso8601String(),
        'xpPoints': newXp,
        'currentLevel': newLevel,
      });
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'streakBonusXp': streakBonusXp,
      'earnedStreakBonus': earnedStreakBonus,
    };
  }

  /// Calculate level based on total XP
  int calculateLevelFromXp(int xp) {
    if (xp < 500) return xp ~/ 250 + 1; // Levels 1-2: 0-499
    if (xp < 1500) return (xp - 500) ~/ 250 + 3; // Levels 3-5: 500-1499
    if (xp < 3000) return (xp - 1500) ~/ 375 + 6; // Levels 6-9: 1500-2999
    if (xp < 5000) return (xp - 3000) ~/ 400 + 10; // Levels 10-14: 3000-4999
    if (xp < 8000) return (xp - 5000) ~/ 600 + 15; // Levels 15-19: 5000-7999
    return (xp - 8000) ~/ 1000 + 20; // Level 20+: 8000+
  }

  /// Get the name of a level tier
  String getLevelName(int level, {bool useHebrew = false}) {
    final tier = LEVEL_TIERS[level] ?? LEVEL_TIERS[20]!;
    return useHebrew ? tier['nameHe'] as String : tier['nameEn'] as String;
  }

  /// Get XP required for next level
  int getXpForNextLevel(int currentXp) {
    final currentLevel = calculateLevelFromXp(currentXp);
    final nextLevelTier = LEVEL_TIERS[currentLevel + 1];

    if (nextLevelTier != null) {
      return nextLevelTier['maxXp'] as int;
    }

    // For level 20+, each level needs 1000 more XP
    return ((currentLevel + 1 - 20) * 1000) + 8000;
  }

  /// Get progress to next level (0.0 to 1.0)
  double getProgressToNextLevel(int currentXp) {
    final currentLevel = calculateLevelFromXp(currentXp);
    final currentLevelMinXp = currentLevel > 1
        ? (LEVEL_TIERS[currentLevel - 1]?['maxXp'] as int? ?? 0)
        : 0;
    final nextLevelXp = getXpForNextLevel(currentXp);

    if (nextLevelXp == currentLevelMinXp) return 1.0;

    final xpIntoLevel = currentXp - currentLevelMinXp;
    final xpNeededForLevel = nextLevelXp - currentLevelMinXp;

    return (xpIntoLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }
}
