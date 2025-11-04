import 'package:flutter/material.dart';
import '../../core/theme/adhd_theme.dart';

/// Atti the Mascot - ADHD-friendly companion for students
/// Positioned prominently to encourage and guide learning
/// Future: Ready for Lottie animations
class AttiMascot extends StatelessWidget {
  final String message;
  final AttiSize size;
  final AttiPosition position;
  final bool showSpeechBubble;

  const AttiMascot({
    super.key,
    required this.message,
    this.size = AttiSize.large,
    this.position = AttiPosition.center,
    this.showSpeechBubble = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech bubble (above Atti)
        if (showSpeechBubble && message.isNotEmpty) ...[
          _buildSpeechBubble(context),
          const SizedBox(height: ADHDTheme.spacingMedium),
        ],

        // Atti mascot avatar
        _buildAttiAvatar(),
      ],
    );
  }

  /// Build Atti's avatar
  /// TODO: Replace with animated Lottie file in future
  Widget _buildAttiAvatar() {
    final double avatarSize = size.dimension;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ADHDTheme.primaryBlue,
            ADHDTheme.secondaryGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ADHDTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '🧠', // Brain emoji represents Atti
          style: TextStyle(
            fontSize: avatarSize * 0.5,
          ),
        ),
      ),
    );
  }

  /// Build speech bubble with message
  Widget _buildSpeechBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: size == AttiSize.large ? 280 : 200,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ADHDTheme.spacingMedium,
        vertical: ADHDTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusMedium),
        border: Border.all(
          color: ADHDTheme.primaryBlue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '💬',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(width: ADHDTheme.spacingSmall),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: size == AttiSize.large
                    ? ADHDTheme.fontSizeMedium
                    : ADHDTheme.fontSizeSmall,
                color: ADHDTheme.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Atti size variants
enum AttiSize {
  large(150), // Main homepage hero
  medium(100), // Section headers
  small(60); // Inline encouragement

  final double dimension;
  const AttiSize(this.dimension);
}

/// Atti position on screen
enum AttiPosition {
  left,
  center,
  right;
}

/// Predefined encouraging messages from Atti
class AttiMessages {
  static const List<String> greetings = [
    "Let's learn together today!",
    "Ready for an adventure?",
    "You're going to do great!",
    "Time to have fun learning!",
  ];

  static const List<String> encouragement = [
    "You're amazing!",
    "Keep it up!",
    "You're doing great!",
    "I'm proud of you!",
    "You're a star!",
    "Awesome work!",
  ];

  static const List<String> motivation = [
    "Let's learn 3 new words today!",
    "Can you beat yesterday's score?",
    "Every lesson makes you smarter!",
    "Practice makes perfect!",
  ];

  static const List<String> celebration = [
    "You did it! 🎉",
    "Incredible! 🌟",
    "Perfect! ⭐",
    "You're the best! 🏆",
  ];

  /// Get random greeting message
  static String getRandomGreeting() {
    final random = DateTime.now().millisecondsSinceEpoch % greetings.length;
    return greetings[random];
  }

  /// Get random encouragement message
  static String getRandomEncouragement() {
    final random = DateTime.now().millisecondsSinceEpoch % encouragement.length;
    return encouragement[random];
  }

  /// Get random motivation message
  static String getRandomMotivation() {
    final random = DateTime.now().millisecondsSinceEpoch % motivation.length;
    return motivation[random];
  }

  /// Get random celebration message
  static String getRandomCelebration() {
    final random = DateTime.now().millisecondsSinceEpoch % celebration.length;
    return celebration[random];
  }

  /// Get context-aware message based on time of day
  static String getTimeBasedMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good morning! Let's start strong! ☀️";
    } else if (hour < 17) {
      return "Good afternoon! You're doing great! 🌤️";
    } else if (hour < 21) {
      return "Good evening! Almost done for today! 🌆";
    } else {
      return "It's late! Rest well and see you tomorrow! 🌙";
    }
  }
}
