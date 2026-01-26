import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/lesson_completion_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Chart showing individual lesson scores for a student
class StudentLessonScoresChart extends StatefulWidget {
  final StudentProgressData progressData;
  final VoidCallback? onClose;

  const StudentLessonScoresChart({
    super.key,
    required this.progressData,
    this.onClose,
  });

  @override
  State<StudentLessonScoresChart> createState() =>
      _StudentLessonScoresChartState();
}

class _StudentLessonScoresChartState extends State<StudentLessonScoresChart> {
  int? _touchedIndex;

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;
    final completions = widget.progressData.completions;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: Colors.purple.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.progressData.studentName,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isRTL
                            ? 'ציונים לפי שיעור'
                            : 'Scores by Lesson',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSmall),

            // Summary stats
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.school,
                    value: '${widget.progressData.lessonsCompleted}',
                    label: isRTL ? 'שיעורים' : 'Lessons',
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    icon: Icons.trending_up,
                    value: '${widget.progressData.averageScore.toStringAsFixed(1)}%',
                    label: isRTL ? 'ממוצע' : 'Average',
                    color: _getScoreColor(widget.progressData.averageScore),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            // Chart or empty state
            if (completions.isEmpty)
              _buildEmptyState(isRTL)
            else
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey.shade800,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final completion = completions[groupIndex];
                          final dateStr = DateFormat('dd/MM/yy')
                              .format(completion.completedAt);
                          return BarTooltipItem(
                            '${completion.lessonTitle}\n'
                            '${completion.percentage.toStringAsFixed(1)}%\n'
                            '${completion.score}/${completion.maxScore} ${isRTL ? "נק" : "pts"}\n'
                            '$dateStr',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                      touchCallback: (event, response) {
                        setState(() {
                          _touchedIndex = response?.spot?.touchedBarGroupIndex;
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= completions.length) {
                              return const SizedBox.shrink();
                            }
                            final title = completions[index].lessonTitle;
                            final shortTitle = title.length > 10
                                ? '${title.substring(0, 8)}...'
                                : title;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  shortTitle,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: _touchedIndex == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                          reservedSize: 35,
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: completions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final completion = entry.value;
                      final color = _getScoreColor(completion.percentage);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: completion.percentage,
                            gradient: LinearGradient(
                              colors: _touchedIndex == index
                                  ? [color.withOpacity(0.9), color.withOpacity(0.7)]
                                  : [color, color.withOpacity(0.8)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: completions.length > 8 ? 15 : 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

            if (completions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                isRTL
                    ? 'הקש על עמודה לפרטים נוספים'
                    : 'Tap a bar for more details',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isRTL) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            isRTL
                ? 'התלמיד עדיין לא השלים שיעורים'
                : 'Student has not completed any lessons yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: AppTheme.fontSizeMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
