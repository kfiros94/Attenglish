import 'package:flutter/material.dart';
import '../models/lesson_completion_model.dart';
import '../services/progress_service.dart';
import '../widgets/class_progress_charts.dart';
import '../widgets/student_detail_chart.dart';
import '../../classroom/models/class_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Screen for viewing student progress and analytics
class StudentProgressScreen extends StatefulWidget {
  final String teacherId;

  const StudentProgressScreen({
    super.key,
    required this.teacherId,
  });

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final ProgressService _progressService = ProgressService();

  List<ClassModel> _classrooms = [];
  ClassModel? _selectedClassroom;
  TimeRange _selectedTimeRange = TimeRange.week;
  List<StudentProgressData> _progressData = [];
  StudentProgressData? _selectedStudent;

  bool _isLoadingClassrooms = true;
  bool _isLoadingProgress = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoadingClassrooms = true;
      _errorMessage = null;
    });

    try {
      final classrooms = await _progressService.getTeacherClassrooms(
        widget.teacherId,
      );

      setState(() {
        _classrooms = classrooms;
        _isLoadingClassrooms = false;
        if (classrooms.isNotEmpty) {
          _selectedClassroom = classrooms.first;
          _loadClassProgress();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingClassrooms = false;
      });
    }
  }

  Future<void> _loadClassProgress() async {
    if (_selectedClassroom == null) return;

    setState(() {
      _isLoadingProgress = true;
      _errorMessage = null;
      _selectedStudent = null;
    });

    try {
      final progress = await _progressService.getClassProgress(
        _selectedClassroom!.id,
        timeRange: _selectedTimeRange,
      );

      setState(() {
        _progressData = progress;
        _isLoadingProgress = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingProgress = false;
      });
    }
  }

  void _onClassroomChanged(ClassModel? classroom) {
    if (classroom != null && classroom.id != _selectedClassroom?.id) {
      setState(() {
        _selectedClassroom = classroom;
        _selectedStudent = null;
      });
      _loadClassProgress();
    }
  }

  void _onTimeRangeChanged(TimeRange range) {
    if (range != _selectedTimeRange) {
      setState(() {
        _selectedTimeRange = range;
      });
      _loadClassProgress();
    }
  }

  void _onStudentTap(String studentId, String studentName) {
    final studentData = _progressData.firstWhere(
      (p) => p.studentId == studentId,
      orElse: () => StudentProgressData(
        studentId: studentId,
        studentName: studentName,
        lessonsCompleted: 0,
        averageScore: 0,
        completions: [],
      ),
    );

    setState(() {
      _selectedStudent = studentData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRTL ? 'התקדמות התלמידים' : 'Student Progress'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingClassrooms
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _classrooms.isEmpty
              ? _buildErrorState(isRTL)
              : _classrooms.isEmpty
                  ? _buildNoClassroomsState(isRTL)
                  : _buildContent(isRTL),
    );
  }

  Widget _buildContent(bool isRTL) {
    return RefreshIndicator(
      onRefresh: _loadClassProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Classroom selector
            _buildClassroomSelector(isRTL),
            const SizedBox(height: AppTheme.spacingMedium),

            // Time range filter
            _buildTimeRangeFilter(isRTL),
            const SizedBox(height: AppTheme.spacingMedium),

            // Loading indicator
            if (_isLoadingProgress)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Section header: Macro View
              _buildSectionHeader(
                icon: Icons.groups,
                title: isRTL ? 'מבט כללי על הכיתה' : 'Class Overview',
                isRTL: isRTL,
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Lessons Completed Chart
              LessonsCompletedChart(
                progressData: _progressData,
                onStudentTap: _onStudentTap,
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Average Score Chart
              AverageScoreChart(
                progressData: _progressData,
                onStudentTap: _onStudentTap,
              ),
              const SizedBox(height: AppTheme.spacingLarge),

              // Selected Student Detail (Micro View)
              if (_selectedStudent != null) ...[
                _buildSectionHeader(
                  icon: Icons.person,
                  title: isRTL ? 'פרטי תלמיד' : 'Student Detail',
                  isRTL: isRTL,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                StudentLessonScoresChart(
                  progressData: _selectedStudent!,
                  onClose: () {
                    setState(() {
                      _selectedStudent = null;
                    });
                  },
                ),
              ],

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomSelector(bool isRTL) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingSmall),
        child: Row(
          children: [
            const Icon(Icons.class_, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ClassModel>(
                  value: _selectedClassroom,
                  isExpanded: true,
                  hint: Text(isRTL ? 'בחר כיתה' : 'Select Classroom'),
                  items: _classrooms.map((classroom) {
                    return DropdownMenuItem<ClassModel>(
                      value: classroom,
                      child: Text(
                        '${classroom.name} (${classroom.studentIds.length} ${isRTL ? "תלמידים" : "students"})',
                      ),
                    );
                  }).toList(),
                  onChanged: _onClassroomChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeFilter(bool isRTL) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall,
          vertical: 4,
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              isRTL ? 'תקופה:' : 'Period:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTimeRangeChip(
                      label: isRTL ? 'יום' : 'Day',
                      value: TimeRange.day,
                      isRTL: isRTL,
                    ),
                    const SizedBox(width: 4),
                    _buildTimeRangeChip(
                      label: isRTL ? 'שבוע' : 'Week',
                      value: TimeRange.week,
                      isRTL: isRTL,
                    ),
                    const SizedBox(width: 4),
                    _buildTimeRangeChip(
                      label: isRTL ? 'חודש' : 'Month',
                      value: TimeRange.month,
                      isRTL: isRTL,
                    ),
                    const SizedBox(width: 4),
                    _buildTimeRangeChip(
                      label: isRTL ? 'הכל' : 'All',
                      value: TimeRange.all,
                      isRTL: isRTL,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip({
    required String label,
    required TimeRange value,
    required bool isRTL,
  }) {
    final isSelected = _selectedTimeRange == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => _onTimeRangeChanged(value),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isRTL,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isRTL) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              isRTL ? 'שגיאה בטעינת הנתונים' : 'Error loading data',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadClassrooms,
              icon: const Icon(Icons.refresh),
              label: Text(isRTL ? 'נסה שוב' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoClassroomsState(bool isRTL) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isRTL ? 'אין כיתות' : 'No Classrooms',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRTL
                  ? 'צור כיתה כדי להתחיל לעקוב אחר התקדמות התלמידים'
                  : 'Create a classroom to start tracking student progress',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
