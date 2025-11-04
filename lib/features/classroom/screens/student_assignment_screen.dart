import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../classroom/models/class_model.dart';
import '../../classroom/services/class_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/localization_service.dart';

/// Screen for teachers to assign students to their classrooms
class StudentAssignmentScreen extends StatefulWidget {
  final ClassModel classroom;

  const StudentAssignmentScreen({
    super.key,
    required this.classroom,
  });

  @override
  State<StudentAssignmentScreen> createState() =>
      _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  /// Get students from the same school and grade who are not assigned to any classroom
  Stream<List<UserModel>> _getAvailableStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('schoolName', isEqualTo: widget.classroom.schoolName)
        .where('grade', isEqualTo: widget.classroom.grade)
        .snapshots()
        .map((snapshot) {
      final students = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((student) =>
              student.classId == null || student.classId!.isEmpty)
          .toList();

      // Sort by name
      students.sort((a, b) => a.fullName.compareTo(b.fullName));
      return students;
    });
  }

  /// Get students already assigned to this classroom
  Stream<List<UserModel>> _getAssignedStudents() {
    return _firestore
        .collection('users')
        .where('classId', isEqualTo: widget.classroom.id)
        .snapshots()
        .map((snapshot) {
      final students =
          snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();

      // Sort by name
      students.sort((a, b) => a.fullName.compareTo(b.fullName));
      return students;
    });
  }

  /// Assign student to classroom
  Future<void> _assignStudent(UserModel student) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ClassService.instance
          .addStudentToClass(widget.classroom.id, student.id);

      if (mounted) {
        final isRTL = LocalizationService.instance.isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL
                  ? '${student.fullName} נוסף לכיתה'
                  : '${student.fullName} added to classroom',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isRTL = LocalizationService.instance.isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'שגיאה בהוספת תלמיד: $e' : 'Error adding student: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Remove student from classroom
  Future<void> _removeStudent(UserModel student) async {
    final isRTL = LocalizationService.instance.isRTL;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'הסרת תלמיד' : 'Remove Student'),
        content: Text(
          isRTL
              ? 'האם להסיר את ${student.fullName} מהכיתה?'
              : 'Remove ${student.fullName} from classroom?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              isRTL ? 'ביטול' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isRTL ? 'הסר' : 'Remove',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ClassService.instance
            .removeStudentFromClass(widget.classroom.id, student.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL
                    ? '${student.fullName} הוסר מהכיתה'
                    : '${student.fullName} removed from classroom',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRTL
                    ? 'שגיאה בהסרת תלמיד: $e'
                    : 'Error removing student: $e',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = LocalizationService.instance.isRTL;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRTL ? 'ניהול תלמידים' : 'Manage Students',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.fontSizeLarge,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.classroom.name} - ${isRTL ? 'כיתה' : 'Grade'} ${widget.classroom.grade}',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Tab bar
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.people),
                  text: isRTL ? 'תלמידים בכיתה' : 'In Classroom',
                ),
                Tab(
                  icon: const Icon(Icons.person_add),
                  text: isRTL ? 'תלמידים זמינים' : 'Available',
                ),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  // Assigned students tab
                  StreamBuilder<List<UserModel>>(
                    stream: _getAssignedStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            isRTL
                                ? 'שגיאה בטעינת תלמידים'
                                : 'Error loading students',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }

                      final students = snapshot.data ?? [];

                      if (students.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: AppTheme.spacingMedium),
                              Text(
                                isRTL ? 'אין תלמידים בכיתה' : 'No students yet',
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeLarge,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              Text(
                                isRTL
                                    ? 'לחץ על "תלמידים זמינים" להוספה'
                                    : 'Tap "Available" to add students',
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentCard(
                            student: student,
                            isAssigned: true,
                            onTap: () => _removeStudent(student),
                            isRTL: isRTL,
                          );
                        },
                      );
                    },
                  ),

                  // Available students tab
                  StreamBuilder<List<UserModel>>(
                    stream: _getAvailableStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            isRTL
                                ? 'שגיאה בטעינת תלמידים'
                                : 'Error loading students',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }

                      final students = snapshot.data ?? [];

                      if (students.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 80,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: AppTheme.spacingMedium),
                              Text(
                                isRTL
                                    ? 'אין תלמידים זמינים'
                                    : 'No available students',
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeLarge,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              Text(
                                isRTL
                                    ? 'אין תלמידים רשומים בבית ספר זה וכיתה ${widget.classroom.grade}'
                                    : 'No students from ${widget.classroom.schoolName}, Grade ${widget.classroom.grade}',
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  color: AppColors.textTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentCard(
                            student: student,
                            isAssigned: false,
                            onTap: () => _assignStudent(student),
                            isRTL: isRTL,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build student card
  Widget _buildStudentCard({
    required UserModel student,
    required bool isAssigned,
    required VoidCallback onTap,
    required bool isRTL,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: isAssigned
                ? AppColors.success.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            isAssigned ? Icons.check_circle : Icons.person_add,
            color: isAssigned ? AppColors.success : AppColors.primary,
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '@${student.userName} • ${student.city}',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : IconButton(
                icon: Icon(
                  isAssigned ? Icons.remove_circle : Icons.add_circle,
                  color: isAssigned ? AppColors.error : AppColors.success,
                ),
                onPressed: onTap,
                tooltip: isAssigned
                    ? (isRTL ? 'הסר מכיתה' : 'Remove from classroom')
                    : (isRTL ? 'הוסף לכיתה' : 'Add to classroom'),
              ),
      ),
    );
  }
}
