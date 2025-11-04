import 'package:flutter/material.dart';
import '../../../core/theme/adhd_theme.dart';

/// ADHD-friendly mission/lesson card for students
/// Large, colorful, with clear call-to-action
class MissionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final int points;
  final VoidCallback onTap;
  final MissionType type;

  const MissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.points,
    required this.onTap,
    this.type = MissionType.lesson,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ADHDTheme.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(ADHDTheme.spacingMedium),
          decoration: ADHDTheme.missionCardDecoration.copyWith(
            border: Border.all(
              color: widget.type.color.withOpacity(_isPressed ? 0.8 : 0.3),
              width: 3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and type indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconCircle(),
                  _buildTypeLabel(),
                ],
              ),
              const SizedBox(height: ADHDTheme.spacingMedium),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: ADHDTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: ADHDTheme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: ADHDTheme.spacingSmall),

              // Subtitle
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: ADHDTheme.fontSizeMedium,
                  color: ADHDTheme.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: ADHDTheme.spacingMedium),

              // Duration and Points
              Row(
                children: [
                  _buildInfoChip(
                    icon: '⏱️',
                    text: '${widget.durationMinutes} min',
                    color: ADHDTheme.primaryBlue,
                  ),
                  const SizedBox(width: ADHDTheme.spacingSmall),
                  _buildInfoChip(
                    icon: '⭐',
                    text: '+${widget.points} pts',
                    color: ADHDTheme.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: ADHDTheme.spacingMedium),

              // Start button
              SizedBox(
                width: double.infinity,
                height: ADHDTheme.buttonHeightMedium,
                child: ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.type.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ADHDTheme.radiusMedium,
                      ),
                    ),
                    elevation: ADHDTheme.elevationLow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 28),
                      const SizedBox(width: ADHDTheme.spacingSmall),
                      Text(
                        widget.type == MissionType.lesson
                            ? 'START LESSON'
                            : 'PRACTICE NOW',
                        style: const TextStyle(
                          fontSize: ADHDTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build icon circle
  Widget _buildIconCircle() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.type.color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.icon,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  /// Build type label (NEW/PRACTICE)
  Widget _buildTypeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ADHDTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: widget.type.color,
        borderRadius: BorderRadius.circular(ADHDTheme.radiusSmall),
      ),
      child: Text(
        widget.type.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build info chip (duration/points)
  Widget _buildInfoChip({
    required String icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ADHDTheme.spacingSmall,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ADHDTheme.radiusSmall),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: ADHDTheme.fontSizeSmall,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mission type (lesson vs practice)
enum MissionType {
  lesson(
    label: 'NEW',
    color: ADHDTheme.primaryBlue,
  ),
  practice(
    label: 'PRACTICE',
    color: ADHDTheme.secondaryGreen,
  );

  final String label;
  final Color color;

  const MissionType({
    required this.label,
    required this.color,
  });
}
