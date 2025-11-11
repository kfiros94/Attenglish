import 'package:flutter/material.dart';
import '../models/ai_response_model.dart';
import '../../lessons/models/activity_model.dart';

/// Screen for reviewing AI-generated activities before adding to lesson
///
/// Allows teachers to:
/// - Review all generated activities
/// - Filter by activity type
/// - Select/deselect activities
/// - Edit or delete activities
/// - Add selected activities to lesson
class ReviewActivitiesScreen extends StatefulWidget {
  final AiGenerationResponse response;

  const ReviewActivitiesScreen({
    super.key,
    required this.response,
  });

  @override
  State<ReviewActivitiesScreen> createState() => _ReviewActivitiesScreenState();
}

class _ReviewActivitiesScreenState extends State<ReviewActivitiesScreen> {
  // Copy of activities from response (can be modified)
  late List<ActivityModel> _activities;

  // Selection state for each activity
  late List<bool> _selectedActivities;

  // Current filter type
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();

    // Copy activities from response
    _activities = List.from(widget.response.activities);

    // Initialize all as selected
    _selectedActivities = List.filled(_activities.length, true);
  }

  /// Returns filtered activities based on current filter
  List<ActivityModel> _getFilteredActivities() {
    if (_filterType == 'all') {
      return _activities;
    }
    return _activities.where((activity) => activity.type == _filterType).toList();
  }

  /// Returns count of selected activities
  int _getSelectedCount() {
    return _selectedActivities.where((selected) => selected).length;
  }

  /// Toggles selection for activity at index
  void _toggleSelection(int index) {
    setState(() {
      _selectedActivities[index] = !_selectedActivities[index];
    });
  }

  /// Toggles all selections (select all / deselect all)
  void _toggleAllSelections() {
    final allSelected = _selectedActivities.every((selected) => selected);

    setState(() {
      if (allSelected) {
        // Deselect all
        _selectedActivities = List.filled(_activities.length, false);
      } else {
        // Select all
        _selectedActivities = List.filled(_activities.length, true);
      }
    });
  }

  /// Deletes selected activities
  void _onDeleteSelected() {
    // Check if any activities are selected
    if (_getSelectedCount() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select activities to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activities'),
        content: Text(
          'Are you sure you want to delete ${_getSelectedCount()} selected activities?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove selected activities
              setState(() {
                for (int i = _activities.length - 1; i >= 0; i--) {
                  if (_selectedActivities[i]) {
                    _activities.removeAt(i);
                    _selectedActivities.removeAt(i);
                  }
                }
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected activities deleted'),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Adds selected activities to lesson
  void _onAddToLesson() {
    // Get selected activities
    final selectedActivities = <ActivityModel>[];
    for (int i = 0; i < _activities.length; i++) {
      if (_selectedActivities[i]) {
        selectedActivities.add(_activities[i]);
      }
    }

    // Check if any activities are selected
    if (selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one activity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Return selected activities to previous screen
    Navigator.pop(context, selectedActivities);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedActivities.length} activities added to lesson'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Gets count of activities by type
  int _getCountByType(String type) {
    return _activities.where((activity) => activity.type == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedActivities.every((selected) => selected);

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Activities (${_activities.length})'),
        actions: [
          IconButton(
            icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
            onPressed: _toggleAllSelections,
            tooltip: allSelected ? 'Deselect All' : 'Select All',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _onDeleteSelected,
            tooltip: 'Delete Selected',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          _buildSummaryCard(),

          // Filter Bar
          _buildFilterBar(),

          // Activities List
          Expanded(
            child: _buildActivitiesList(),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  /// Builds the summary card at the top
  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated ${_activities.length} activities in ${widget.response.generationTime.inSeconds}s',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_getCountByType('multiple_choice') > 0)
                  Chip(
                    label: Text('Multiple Choice: ${_getCountByType('multiple_choice')}'),
                    avatar: const Icon(Icons.radio_button_checked, size: 16),
                  ),
                if (_getCountByType('fill_blank') > 0)
                  Chip(
                    label: Text('Fill Blank: ${_getCountByType('fill_blank')}'),
                    avatar: const Icon(Icons.edit, size: 16),
                  ),
                if (_getCountByType('true_false') > 0)
                  Chip(
                    label: Text('True/False: ${_getCountByType('true_false')}'),
                    avatar: const Icon(Icons.check_circle, size: 16),
                  ),
                if (_getCountByType('drag_drop') > 0)
                  Chip(
                    label: Text('Drag & Drop: ${_getCountByType('drag_drop')}'),
                    avatar: const Icon(Icons.swap_horiz, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.response.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the filter bar
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterType == 'all',
            onSelected: (selected) {
              setState(() => _filterType = 'all');
            },
          ),
          FilterChip(
            label: const Text('Multiple Choice'),
            selected: _filterType == 'multiple_choice',
            onSelected: (selected) {
              setState(() => _filterType = 'multiple_choice');
            },
          ),
          FilterChip(
            label: const Text('Fill Blank'),
            selected: _filterType == 'fill_blank',
            onSelected: (selected) {
              setState(() => _filterType = 'fill_blank');
            },
          ),
          FilterChip(
            label: const Text('True/False'),
            selected: _filterType == 'true_false',
            onSelected: (selected) {
              setState(() => _filterType = 'true_false');
            },
          ),
          FilterChip(
            label: const Text('Drag & Drop'),
            selected: _filterType == 'drag_drop',
            onSelected: (selected) {
              setState(() => _filterType = 'drag_drop');
            },
          ),
        ],
      ),
    );
  }

  /// Builds the activities list
  Widget _buildActivitiesList() {
    final filteredActivities = _getFilteredActivities();

    if (filteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No activities match this filter',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredActivities.length,
      itemBuilder: (context, filteredIndex) {
        // Find the actual index in _activities list
        final activity = filteredActivities[filteredIndex];
        final actualIndex = _activities.indexOf(activity);

        return ActivityReviewCard(
          activity: activity,
          isSelected: _selectedActivities[actualIndex],
          index: filteredIndex,
          onToggleSelect: () => _toggleSelection(actualIndex),
          onEdit: () {
            // TODO: Implement edit functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Edit functionality coming soon'),
              ),
            );
          },
          onDelete: () {
            setState(() {
              _activities.removeAt(actualIndex);
              _selectedActivities.removeAt(actualIndex);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Activity deleted'),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the bottom action bar
  Widget _buildBottomActionBar() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            Text(
              '${_getSelectedCount()} selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: _onAddToLesson,
                icon: const Icon(Icons.add_circle),
                label: const Text('Add to Lesson'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for displaying and interacting with a single activity
class ActivityReviewCard extends StatelessWidget {
  final ActivityModel activity;
  final bool isSelected;
  final int index;
  final VoidCallback onToggleSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActivityReviewCard({
    super.key,
    required this.activity,
    required this.isSelected,
    required this.index,
    required this.onToggleSelect,
    this.onEdit,
    this.onDelete,
  });

  /// Gets icon for activity type
  IconData _getIconForType(String type) {
    switch (type) {
      case 'multiple_choice':
        return Icons.radio_button_checked;
      case 'fill_blank':
        return Icons.edit;
      case 'true_false':
        return Icons.check_circle;
      case 'drag_drop':
        return Icons.swap_horiz;
      default:
        return Icons.help_outline;
    }
  }

  /// Gets color for activity type
  Color _getColorForType(String type) {
    switch (type) {
      case 'multiple_choice':
        return Colors.blue;
      case 'fill_blank':
        return Colors.orange;
      case 'true_false':
        return Colors.green;
      case 'drag_drop':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Gets display name for activity type
  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'true_false':
        return 'True/False';
      case 'drag_drop':
        return 'Drag & Drop';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          CheckboxListTile(
            value: isSelected,
            onChanged: (_) => onToggleSelect(),
            title: Row(
              children: [
                Icon(
                  _getIconForType(activity.type),
                  color: _getColorForType(activity.type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.question,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _getTypeDisplayName(activity.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getColorForType(activity.type),
                  ),
                ),
                const SizedBox(height: 8),
                _buildActivityDetails(context),
                const SizedBox(height: 4),
                Text(
                  '${activity.points} points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds activity-specific details based on type
  Widget _buildActivityDetails(BuildContext context) {
    switch (activity.type) {
      case 'multiple_choice':
        return _buildMultipleChoiceDetails(context);
      case 'fill_blank':
        return _buildFillBlankDetails(context);
      case 'true_false':
        return _buildTrueFalseDetails(context);
      case 'drag_drop':
        return _buildDragDropDetails(context);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds multiple choice activity details
  Widget _buildMultipleChoiceDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activity.options!.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isCorrect = index == activity.correctAnswer;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: isCorrect ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCorrect ? Colors.green.shade700 : null,
                      fontWeight: isCorrect ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Builds fill in the blank activity details
  Widget _buildFillBlankDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.blankSentence ?? '',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Answer: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                activity.correctWord ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds true/false activity details
  Widget _buildTrueFalseDetails(BuildContext context) {
    final isTrue = activity.correctAnswer == true;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check : Icons.close,
            size: 20,
            color: isTrue ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            isTrue ? 'TRUE' : 'FALSE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isTrue ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds drag and drop activity details
  Widget _buildDragDropDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Matching pairs:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...activity.correctPairs!.entries.take(3).map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (activity.correctPairs!.length > 3)
            Text(
              '+ ${activity.correctPairs!.length - 3} more pairs',
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
