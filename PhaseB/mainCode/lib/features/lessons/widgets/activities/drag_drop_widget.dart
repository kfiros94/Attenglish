import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../lessons/models/activity_model.dart';

/// Enhanced Widget for displaying and interacting with drag & drop matching activities
/// Students drag items from the left column to match with items on the right
class DragDropWidget extends StatefulWidget {
  final ActivityModel activity;
  final Function(bool isCorrect, int points) onAnswered;

  const DragDropWidget({
    super.key,
    required this.activity,
    required this.onAnswered,
  });

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget>
    with TickerProviderStateMixin {
  List<String> _shuffledLeftItems = [];
  List<String> _shuffledRightItems = [];
  Map<String, String?> _userPairs = {}; // left item -> right item (or null)
  Map<String, String> _correctPairs = {}; // Correct mapping
  bool _hasSubmitted = false;
  int _correctCount = 0;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  String? _lastMatchedItem;

  @override
  void initState() {
    super.initState();

    // Copy and shuffle items
    _shuffledLeftItems = List.from(widget.activity.leftItems!);
    _shuffledRightItems = List.from(widget.activity.rightItems!);
    _shuffledRightItems.shuffle(); // Shuffle right items only

    // Initialize user pairs (all unmatched)
    for (final leftItem in _shuffledLeftItems) {
      _userPairs[leftItem] = null;
    }

    // Copy correct pairs
    _correctPairs = Map.from(widget.activity.correctPairs!);

    // Initialize animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedCount = _userPairs.values.where((v) => v != null).length;
    final totalPairs = _shuffledLeftItems.length;
    final progress = matchedCount / totalPairs;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      color: Colors.purple.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.activity.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar with animation
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Matched: $matchedCount / $totalPairs',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (matchedCount == totalPairs && !_hasSubmitted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Ready!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Instructions with better styling
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag English words to their Hebrew translations',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Matching Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column (draggable items)
                  Expanded(child: _buildLeftColumn()),

                  const SizedBox(width: 20),

                  // Right column (drop targets)
                  Expanded(child: _buildRightColumn()),
                ],
              ),

              const SizedBox(height: 24),

              // Submit Button (if not submitted and all matched)
              if (!_hasSubmitted && _isAllMatched())
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _onSubmit,
                        icon: const Icon(Icons.check_circle, size: 24),
                        label: const Text(
                          'Check My Answers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Feedback (if submitted)
              if (_hasSubmitted) _buildFeedback(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.abc, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'English',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _shuffledLeftItems.length; i++)
          _buildDraggableItem(i),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.translate, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'עברית',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _shuffledRightItems.length; i++)
          _buildDropTarget(i),
      ],
    );
  }

  Widget _buildDraggableItem(int leftIndex) {
    final item = _shuffledLeftItems[leftIndex];
    final isMatched = _userPairs[item] != null;
    final isLastMatched = _lastMatchedItem == item;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Draggable<String>(
        data: item,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildItemCard(
            item,
            Colors.blue,
            true,
            false,
          ),
        ),
        onDragStarted: () {
          HapticFeedback.lightImpact();
        },
        child: _buildItemCard(
          item,
          Colors.blue,
          isMatched,
          isLastMatched,
        ),
      ),
    );
  }

  Widget _buildDropTarget(int rightIndex) {
    final rightItem = _shuffledRightItems[rightIndex];

    // Find if any left item is matched to this right item
    final matchedLeftItem = _userPairs.entries
        .firstWhere(
          (entry) => entry.value == rightItem,
          orElse: () => const MapEntry('', null),
        )
        .key;

    final hasMatch = matchedLeftItem.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => !_hasSubmitted,
        onAcceptWithDetails: (details) {
          final leftItem = details.data;
          setState(() {
            // Remove previous match if exists
            _userPairs.forEach((key, value) {
              if (value == rightItem && key != leftItem) {
                _userPairs[key] = null;
              }
            });

            // Set new match
            _userPairs[leftItem] = rightItem;
            _lastMatchedItem = leftItem;

            // Haptic feedback
            HapticFeedback.mediumImpact();

            // Trigger celebration animation
            _celebrationController.forward(from: 0);
          });

          // Clear last matched after animation
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                _lastMatchedItem = null;
              });
            }
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isHovering
                  ? LinearGradient(
                      colors: [Colors.green.shade200, Colors.green.shade300],
                    )
                  : hasMatch
                      ? LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100],
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade50, Colors.grey.shade100],
                        ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering
                    ? Colors.green.shade600
                    : hasMatch
                        ? Colors.green.shade400
                        : Colors.grey.shade300,
                width: isHovering ? 3 : 2,
              ),
              boxShadow: [
                if (isHovering || hasMatch)
                  BoxShadow(
                    color: (isHovering ? Colors.green : Colors.green.shade300)
                        .withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasMatch ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: hasMatch ? Colors.green.shade700 : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rightItem,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: hasMatch
                              ? Colors.green.shade900
                              : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (hasMatch) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link,
                                  size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  matchedLeftItem,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _userPairs[matchedLeftItem] = null;
                            });
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(
    String text,
    MaterialColor color,
    bool isDimmed,
    bool isAnimating,
  ) {
    return AnimatedBuilder(
      animation: isAnimating ? _celebrationController : _pulseController,
      builder: (context, child) {
        final animationValue =
            isAnimating ? _celebrationController.value : _pulseController.value;
        final scale = isAnimating ? 1.0 + (animationValue * 0.1) : 1.0;
        final pulseOpacity = isDimmed ? 0.5 : (0.9 + (animationValue * 0.1));

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: pulseOpacity,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isDimmed
                    ? LinearGradient(
                        colors: [Colors.grey.shade200, Colors.grey.shade300],
                      )
                    : LinearGradient(
                        colors: [color.shade50, color.shade100],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDimmed ? Colors.grey.shade400 : color.shade400,
                  width: 2,
                ),
                boxShadow: [
                  if (!isDimmed)
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDimmed)
                    Icon(Icons.check_circle,
                        size: 18, color: Colors.grey.shade600),
                  if (isDimmed) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDimmed ? Colors.grey.shade600 : color.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isAllMatched() {
    return !_userPairs.values.contains(null);
  }

  void _onSubmit() {
    // Check how many are correct
    int correct = 0;
    _userPairs.forEach((leftItem, rightItem) {
      if (rightItem != null && _correctPairs[leftItem] == rightItem) {
        correct++;
      }
    });

    final total = _shuffledLeftItems.length;
    final isAllCorrect = correct == total;

    setState(() {
      _hasSubmitted = true;
      _correctCount = correct;
    });

    // Haptic feedback
    if (isAllCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // Call onAnswered immediately to update score
    widget.onAnswered(isAllCorrect, widget.activity.points);
  }

  Widget _buildFeedback() {
    final total = _shuffledLeftItems.length;
    final isAllCorrect = _correctCount == total;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAllCorrect
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.orange.shade50, Colors.orange.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAllCorrect ? Colors.green.shade400 : Colors.orange.shade400,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAllCorrect ? Colors.green : Colors.orange)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              isAllCorrect ? Icons.celebration : Icons.emoji_events,
              size: 56,
              color: isAllCorrect ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              isAllCorrect
                  ? 'Perfect! All matches correct! 🎉'
                  : 'Good try! You got $_correctCount out of $total correct',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isAllCorrect
                    ? Colors.green.shade900
                    : Colors.orange.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${widget.activity.points} points',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (!isAllCorrect) ...[
              const SizedBox(height: 12),
              Text(
                'Keep practicing! 💪',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
