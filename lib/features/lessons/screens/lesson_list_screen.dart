import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../classroom/services/class_service.dart';
import '../../classroom/models/class_model.dart';
import '../../auth/services/auth_service.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import 'create_lesson_screen.dart';
import 'lesson_detail_screen.dart';

/// Screen for displaying all teacher's lessons
/// Includes filtering, search, and actions
class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final _searchController = TextEditingController();

  String? _selectedClassId;
  String _selectedStatus = 'all'; // 'all', 'draft', 'published'
  String _searchQuery = '';

  List<ClassModel> _teacherClasses = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load teacher's classes for filter dropdown
  Future<void> _loadTeacherClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        _teacherClasses = await ClassService.instance.getTeacherClasses(user.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  /// Navigate to create lesson screen
  Future<void> _navigateToCreateLesson() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateLessonScreen(),
      ),
    );

    // Refresh if lesson was created
    if (result == true) {
      setState(() {}); // Trigger rebuild to refresh stream
    }
  }

  /// Navigate to edit lesson screen
  Future<void> _navigateToEditLesson(String lessonId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateLessonScreen(lessonId: lessonId),
      ),
    );

    // Refresh if lesson was updated
    if (result == true) {
      setState(() {}); // Trigger rebuild to refresh stream
    }
  }

  /// Navigate to lesson detail screen
  void _navigateToLessonDetail(String lessonId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lessonId: lessonId),
      ),
    );
  }

  /// Delete lesson with confirmation
  Future<void> _deleteLesson(LessonModel lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text(
          'Are you sure you want to delete "${lesson.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await LessonService.instance.deleteLesson(lesson.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Trigger rebuild to refresh stream
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete lesson: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Get classroom name by ID
  String _getClassroomName(String classId) {
    final classroom = _teacherClasses.firstWhere(
      (c) => c.id == classId,
      orElse: () => ClassModel(
        id: classId,
        name: 'Unknown',
        teacherId: '',
        grade: 0,
        schoolName: '',
        studentIds: [],
        createdAt: DateTime.now(),
      ),
    );
    return classroom.name;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lessons'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateLesson,
        icon: const Icon(Icons.add),
        label: const Text('Create New Lesson'),
      ),
      body: Column(
        children: [
          // Filters and search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search lessons by title...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),

                // Filter row
                Row(
                  children: [
                    // Classroom filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Classroom',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Classrooms'),
                          ),
                          ..._teacherClasses.map((classroom) {
                            return DropdownMenuItem(
                              value: classroom.id,
                              child: Text(classroom.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedClassId = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('Published'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lessons list
          Expanded(
            child: StreamBuilder<List<LessonModel>>(
              stream: LessonService.instance.teacherLessonsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                var lessons = snapshot.data ?? [];

                // Apply filters
                if (_selectedClassId != null) {
                  lessons = lessons
                      .where((lesson) => lesson.classId == _selectedClassId)
                      .toList();
                }

                if (_selectedStatus != 'all') {
                  lessons = lessons
                      .where((lesson) => lesson.status == _selectedStatus)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  lessons = lessons
                      .where((lesson) => lesson.title
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                // Empty state
                if (lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.library_books,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _selectedClassId != null ||
                                  _selectedStatus != 'all'
                              ? 'No lessons match your filters'
                              : 'No lessons yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty ||
                                  _selectedClassId != null ||
                                  _selectedStatus != 'all'
                              ? 'Try adjusting your filters'
                              : 'Create your first lesson to get started!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        if (_searchQuery.isEmpty &&
                            _selectedClassId == null &&
                            _selectedStatus == 'all')
                          ElevatedButton.icon(
                            onPressed: _navigateToCreateLesson,
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Lesson'),
                          ),
                      ],
                    ),
                  );
                }

                // Lessons grid
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return _buildLessonCard(lesson);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual lesson card
  Widget _buildLessonCard(LessonModel lesson) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: lesson.status == 'published'
              ? Colors.green.shade200
              : Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToLessonDetail(lesson.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status badge and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: lesson.status == 'published'
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lesson.statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _navigateToEditLesson(lesson.id),
                        tooltip: 'Edit',
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteLesson(lesson),
                        tooltip: 'Delete',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Topic (if available)
              if (lesson.topic != null) ...[
                Row(
                  children: [
                    const Icon(Icons.topic, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lesson.topic!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              const Spacer(),

              // Bottom info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Classroom and grade
                  Row(
                    children: [
                      const Icon(Icons.class_, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getClassroomName(lesson.classId),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Grade ${lesson.grade}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Difficulty and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.signal_cellular_alt,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lesson.difficultyLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(lesson.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
