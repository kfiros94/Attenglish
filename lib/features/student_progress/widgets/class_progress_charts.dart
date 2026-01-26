import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/lesson_completion_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Chart showing number of lessons completed per student
class LessonsCompletedChart extends StatefulWidget {
  final List<StudentProgressData> progressData;
  final Function(String studentId, String studentName)? onStudentTap;

  const LessonsCompletedChart({
    super.key,
    required this.progressData,
    this.onStudentTap,
  });

  @override
  State<LessonsCompletedChart> createState() => _LessonsCompletedChartState();
}

class _LessonsCompletedChartState extends State<LessonsCompletedChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    if (widget.progressData.isEmpty) {
      return _buildEmptyState(isRTL);
    }

    final maxY = widget.progressData
            .map((p) => p.lessonsCompleted)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() +
        1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  isRTL ? 'שיעורים שהושלמו' : 'Lessons Completed',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade800,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = widget.progressData[groupIndex];
                        return BarTooltipItem(
                          '${data.studentName}\n${data.lessonsCompleted} ${isRTL ? "שיעורים" : "lessons"}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (event is FlTapUpEvent &&
                            response?.spot != null) {
                          final index = response!.spot!.touchedBarGroupIndex;
                          if (index >= 0 &&
                              index < widget.progressData.length) {
                            final data = widget.progressData[index];
                            widget.onStudentTap?.call(
                              data.studentId,
                              data.studentName,
                            );
                          }
                        }
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
                          if (index < 0 ||
                              index >= widget.progressData.length) {
                            return const SizedBox.shrink();
                          }
                          final name = widget.progressData[index].studentName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.7,
                              child: SizedBox(
                                width: 80,
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _touchedIndex == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30,
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
                    horizontalInterval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: widget.progressData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.lessonsCompleted.toDouble(),
                          gradient: LinearGradient(
                            colors: _touchedIndex == index
                                ? [Colors.blue.shade700, Colors.blue.shade400]
                                : [Colors.blue.shade500, Colors.blue.shade300],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 20,
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isRTL) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              isRTL ? 'אין נתונים להצגה' : 'No data to display',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: AppTheme.fontSizeMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chart showing average score per student
class AverageScoreChart extends StatefulWidget {
  final List<StudentProgressData> progressData;
  final Function(String studentId, String studentName)? onStudentTap;

  const AverageScoreChart({
    super.key,
    required this.progressData,
    this.onStudentTap,
  });

  @override
  State<AverageScoreChart> createState() => _AverageScoreChartState();
}

class _AverageScoreChartState extends State<AverageScoreChart> {
  int? _touchedIndex;

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    if (widget.progressData.isEmpty) {
      return _buildEmptyState(isRTL);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  isRTL ? 'ציון ממוצע' : 'Average Score',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, isRTL ? '80%+' : '80%+'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, isRTL ? '50-80%' : '50-80%'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, isRTL ? '<50%' : '<50%'),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
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
                        final data = widget.progressData[groupIndex];
                        return BarTooltipItem(
                          '${data.studentName}\n${data.averageScore.toStringAsFixed(1)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (event is FlTapUpEvent &&
                            response?.spot != null) {
                          final index = response!.spot!.touchedBarGroupIndex;
                          if (index >= 0 &&
                              index < widget.progressData.length) {
                            final data = widget.progressData[index];
                            widget.onStudentTap?.call(
                              data.studentId,
                              data.studentName,
                            );
                          }
                        }
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
                          if (index < 0 ||
                              index >= widget.progressData.length) {
                            return const SizedBox.shrink();
                          }
                          final name = widget.progressData[index].studentName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.7,
                              child: SizedBox(
                                width: 80,
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _touchedIndex == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          );
                        },
                        reservedSize: 60,
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
                  barGroups: widget.progressData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final color = _getScoreColor(data.averageScore);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.averageScore,
                          color: _touchedIndex == index
                              ? color.withOpacity(0.8)
                              : color,
                          width: 20,
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
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isRTL) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              isRTL ? 'אין נתונים להצגה' : 'No data to display',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: AppTheme.fontSizeMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
