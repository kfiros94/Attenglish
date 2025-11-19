import 'package:flutter/material.dart';
import '../models/activity_model.dart';

/// Screen for creating Drag & Drop matching activities
/// Allows teachers to create matching pairs manually
class CreateDragDropScreen extends StatefulWidget {
  const CreateDragDropScreen({super.key});

  @override
  State<CreateDragDropScreen> createState() => _CreateDragDropScreenState();
}

class _CreateDragDropScreenState extends State<CreateDragDropScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _leftItemControllers = [];
  final List<TextEditingController> _rightItemControllers = [];
  int _pairCount = 3; // Start with 3 pairs
  final int _maxPairs = 8; // Maximum 8 pairs
  final int _minPairs = 2; // Minimum 2 pairs

  @override
  void initState() {
    super.initState();
    // Initialize with 3 pairs
    for (int i = 0; i < _pairCount; i++) {
      _leftItemControllers.add(TextEditingController());
      _rightItemControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _leftItemControllers) {
      controller.dispose();
    }
    for (var controller in _rightItemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Drag & Drop'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create matching pairs. Students will drag items from the left to match with items on the right.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Question TextField
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'e.g., Match the English words with their Hebrew translations',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Pairs Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Matching Pairs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _pairCount > _minPairs ? _removePair : null,
                      tooltip: 'Remove pair',
                      color: _pairCount > _minPairs ? Colors.red : Colors.grey,
                    ),
                    Text(
                      '$_pairCount pairs',
                      style: const TextStyle(fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _pairCount < _maxPairs ? _addPair : null,
                      tooltip: 'Add pair',
                      color: _pairCount < _maxPairs ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pairs List
            for (int i = 0; i < _pairCount; i++) _buildPairRow(i),

            const SizedBox(height: 24),

            // Preview Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showPreview,
                icon: const Icon(Icons.preview),
                label: const Text('Preview Activity'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveActivity,
                icon: const Icon(Icons.check),
                label: const Text('Save Activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pair ${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Left item (English)
              Expanded(
                child: TextFormField(
                  controller: _leftItemControllers[index],
                  decoration: const InputDecoration(
                    labelText: 'English',
                    hintText: 'e.g., Cat',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.abc, color: Colors.blue),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Match icon
              const Icon(Icons.arrow_forward, color: Colors.grey),

              const SizedBox(width: 16),

              // Right item (Hebrew)
              Expanded(
                child: TextFormField(
                  controller: _rightItemControllers[index],
                  decoration: const InputDecoration(
                    labelText: 'עברית',
                    hintText: 'e.g., חתול',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate, color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addPair() {
    if (_pairCount < _maxPairs) {
      setState(() {
        _leftItemControllers.add(TextEditingController());
        _rightItemControllers.add(TextEditingController());
        _pairCount++;
      });
    }
  }

  void _removePair() {
    if (_pairCount > _minPairs) {
      setState(() {
        _leftItemControllers.last.dispose();
        _rightItemControllers.last.dispose();
        _leftItemControllers.removeLast();
        _rightItemControllers.removeLast();
        _pairCount--;
      });
    }
  }

  String? _validate() {
    if (_questionController.text.trim().isEmpty) {
      return 'Please enter instructions';
    }

    for (int i = 0; i < _pairCount; i++) {
      if (_leftItemControllers[i].text.trim().isEmpty) {
        return 'Pair ${i + 1}: English word is empty';
      }
      if (_rightItemControllers[i].text.trim().isEmpty) {
        return 'Pair ${i + 1}: Hebrew translation is empty';
      }
    }

    return null;
  }

  void _saveActivity() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Build correct pairs map (left text -> right text)
    final correctPairs = <String, String>{};
    for (int i = 0; i < _pairCount; i++) {
      final leftItem = _leftItemControllers[i].text.trim();
      final rightItem = _rightItemControllers[i].text.trim();
      correctPairs[leftItem] = rightItem;
    }

    // Create activity
    final activity = ActivityModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'drag_drop',
      question: _questionController.text.trim(),
      leftItems: _leftItemControllers.map((c) => c.text.trim()).toList(),
      rightItems: _rightItemControllers.map((c) => c.text.trim()).toList(),
      correctPairs: correctPairs,
      points: _pairCount * 5, // 5 points per pair
    );

    // Return activity
    Navigator.pop(context, activity);
  }

  void _showPreview() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return;
    }

    // Create shuffled preview
    final leftItems = _leftItemControllers.map((c) => c.text.trim()).toList();
    final rightItems = _rightItemControllers.map((c) => c.text.trim()).toList();

    // Shuffle right items for preview
    final shuffledRight = List<String>.from(rightItems)..shuffle();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _questionController.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Left items (in order):',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ...leftItems.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    ),
                  ),
              const SizedBox(height: 16),
              const Text(
                'Right items (shuffled):',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ...shuffledRight.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Create Drag & Drop'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Enter instructions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Tell students what to match (e.g., "Match English words with Hebrew translations")'),
              SizedBox(height: 12),
              Text(
                '2. Create matching pairs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Enter items on the left (English) and right (Hebrew) that match each other'),
              SizedBox(height: 12),
              Text(
                '3. Add or remove pairs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Use the + and - buttons to add or remove pairs (2-8 pairs)'),
              SizedBox(height: 12),
              Text(
                '4. Preview and save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Preview shows how students will see the shuffled items, then save when ready'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
