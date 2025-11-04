import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../classroom/services/class_service.dart';
import '../../classroom/models/class_model.dart';
import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import 'create_lesson_screen.dart';

/// Screen for viewing a single lesson in detail
/// Read-only view with edit and delete actions
class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _isLoading = true;
  LessonModel? _lesson;
  ClassModel? _classroom;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  /// Load lesson and classroom data
  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load lesson
      _lesson = await LessonService.instance.getLesson(widget.lessonId);

      if (_lesson == null) {
        setState(() {
          _errorMessage = 'Lesson not found';
          _isLoading = false;
        });
        return;
      }

      // Load classroom
      _classroom = await ClassService.instance.getClassById(_lesson!.classId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load lesson: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Navigate to edit screen
  Future<void> _editLesson() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateLessonScreen(lessonId: widget.lessonId),
      ),
    );

    // Reload if lesson was updated
    if (result == true) {
      _loadLesson();
    }
  }

  /// Delete lesson with confirmation
  Future<void> _deleteLesson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text(
          'Are you sure you want to delete "${_lesson?.title}"?\n\nThis action cannot be undone.',
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
        await LessonService.instance.deleteLesson(widget.lessonId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return to list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Details'),
        elevation: 0,
        actions: [
          if (_lesson != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editLesson,
              tooltip: 'Edit Lesson',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteLesson,
              tooltip: 'Delete Lesson',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : _lesson == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lesson not found',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _lesson!.status == 'published'
                                      ? Colors.green
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _lesson!.statusLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                _lesson!.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 24),

                              // Info cards row
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  _buildInfoCard(
                                    icon: Icons.class_,
                                    label: 'Classroom',
                                    value: _classroom?.name ?? 'Unknown',
                                    color: Colors.blue,
                                  ),
                                  _buildInfoCard(
                                    icon: Icons.school,
                                    label: 'Grade',
                                    value: 'Grade ${_lesson!.grade}',
                                    color: Colors.purple,
                                  ),
                                  _buildInfoCard(
                                    icon: Icons.signal_cellular_alt,
                                    label: 'Difficulty',
                                    value: _lesson!.difficultyLabel,
                                    color: Colors.orange,
                                  ),
                                  if (_lesson!.topic != null)
                                    _buildInfoCard(
                                      icon: Icons.topic,
                                      label: 'Topic',
                                      value: _lesson!.topic!,
                                      color: Colors.teal,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Description (if available)
                              if (_lesson!.description != null &&
                                  _lesson!.description!.isNotEmpty) ...[
                                _buildSectionHeader('Description'),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    _lesson!.description!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Lesson content
                              _buildSectionHeader('Lesson Content'),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  _lesson!.textContent,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Metadata
                              _buildSectionHeader('Metadata'),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    _buildMetadataRow(
                                      'Created',
                                      _formatDateTime(_lesson!.createdAt),
                                    ),
                                    if (_lesson!.updatedAt != null) ...[
                                      const Divider(),
                                      _buildMetadataRow(
                                        'Last Updated',
                                        _formatDateTime(_lesson!.updatedAt!),
                                      ),
                                    ],
                                    const Divider(),
                                    _buildMetadataRow(
                                      'Lesson ID',
                                      _lesson!.id,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _editLesson,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Lesson'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _deleteLesson,
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete Lesson'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Build info card
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Build metadata row
  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
