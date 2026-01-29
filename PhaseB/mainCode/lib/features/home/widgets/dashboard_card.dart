import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Modern dashboard card with gradient illustration for teacher interface
/// Implements Shneiderman's 8 Golden Rules:
/// 1. Consistency: Uniform hover effects and visual style
/// 2. Universal usability: Tooltips, Semantics labels, keyboard navigation
/// 3. Informative feedback: Hover states, ripple effects, scale animation
/// 5. Prevent errors: Clear visual affordances
/// 8. Reduce memory load: Icons + text, visual grouping
class DashboardCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? badgeText;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? imagePath; // Local asset image path
  final LinearGradient? gradient;
  final List<Color>? gradientColors; // Custom gradient for illustration
  final String? tooltipMessage; // Accessibility tooltip

  const DashboardCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.badgeText,
    required this.onTap,
    this.imageUrl,
    this.imagePath,
    this.gradient,
    this.gradientColors,
    this.tooltipMessage,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get the gradient for the card header
  LinearGradient _getGradient() {
    if (widget.gradient != null) return widget.gradient!;

    if (widget.gradientColors != null && widget.gradientColors!.length >= 2) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.gradientColors!,
      );
    }

    // Default gradient based on icon color
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        widget.iconColor.withOpacity(0.9),
        widget.iconColor.withOpacity(0.7),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;
    final viewText = isRTL ? 'צפה' : 'View';

    // Wrap in Tooltip and Semantics for accessibility (Rule 2)
    Widget card = Semantics(
      button: true,
      label: widget.tooltipMessage ?? widget.title,
      hint: widget.description,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _isHovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: Focus(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withOpacity(_isHovered ? 0.35 : 0.15),
                    blurRadius: _isHovered ? 24 : 12,
                    offset: Offset(0, _isHovered ? 8 : 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    splashColor: widget.iconColor.withOpacity(0.2),
                    highlightColor: widget.iconColor.withOpacity(0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image/Gradient illustration header (top 55%)
                          Expanded(
                            flex: 55,
                            child: Stack(
                              children: [
                                // Background: Local image, network image, or gradient
                                if (widget.imagePath != null)
                                  // Local asset image with light background
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.grey.shade50,
                                      child: Image.asset(
                                        widget.imagePath!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          decoration: BoxDecoration(
                                            gradient: _getGradient(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (widget.imageUrl != null)
                                  // Network image with gradient fallback
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: _getGradient(),
                                      ),
                                      child: Image.network(
                                        widget.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(),
                                      ),
                                    ),
                                  )
                                else ...[
                                  // Gradient background with icon
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: _getGradient(),
                                    ),
                                  ),
                                  // Decorative pattern overlay
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _CardPatternPainter(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  // Large centered icon as illustration
                                  Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: EdgeInsets.all(_isHovered ? 20 : 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(_isHovered ? 0.25 : 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        widget.icon,
                                        size: _isHovered ? 48 : 44,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],

                                // Badge
                                if (widget.badgeText != null)
                                  Positioned(
                                    top: 12,
                                    right: isRTL ? null : 12,
                                    left: isRTL ? 12 : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        widget.badgeText!,
                                        style: TextStyle(
                                          color: widget.iconColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Content section (bottom 45%)
                          Expanded(
                            flex: 45,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  // Description
                                  Expanded(
                                    child: Text(
                                      widget.description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Action button with RTL support (Rule 1: Consistency)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.iconColor.withOpacity(
                                        _isHovered ? 0.15 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          viewText,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: widget.iconColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          isRTL
                                              ? Icons.arrow_back_rounded
                                              : Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: widget.iconColor,
                                        ),
                                      ],
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
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap with Tooltip if message provided (Rule 2: Universal Usability)
    if (widget.tooltipMessage != null) {
      return Tooltip(
        message: widget.tooltipMessage!,
        preferBelow: false,
        child: card,
      );
    }

    return card;
  }
}

/// Custom painter for decorative pattern on card header
class _CardPatternPainter extends CustomPainter {
  final Color color;

  _CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      size.width * 0.15,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      size.width * 0.12,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.9),
      size.width * 0.08,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
