import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import 'add_multiple_choice_screen.dart';
import 'add_fill_blank_screen.dart';
import 'add_true_false_screen.dart';
import '../../ai_generation/screens/ai_generator_screen.dart';
import '../../ai_generation/models/activity_result_model.dart';

/// Screen where teacher chooses which type of activity to create
class SelectActivityTypeScreen extends StatelessWidget {
  const SelectActivityTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Activity Type'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Multiple Choice Card
            _buildActivityTypeCard(
              context: context,
              icon: Icons.radio_button_checked,
              iconColor: Colors.blue,
              title: 'Multiple Choice',
              subtitle: 'Ask a question with 4 options',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMultipleChoiceScreen(),
                  ),
                );
                if (result != null && result is ActivityModel) {
                  Navigator.pop(context, result);
                }
              },
            ),

            const SizedBox(height: 12),

            // Fill in the Blank Card
            _buildActivityTypeCard(
              context: context,
              icon: Icons.edit,
              iconColor: Colors.green,
              title: 'Fill in the Blank',
              subtitle: 'Complete the missing word',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFillBlankScreen(),
                  ),
                );
                if (result != null && result is ActivityModel) {
                  Navigator.pop(context, result);
                }
              },
            ),

            const SizedBox(height: 12),

            // True or False Card
            _buildActivityTypeCard(
              context: context,
              icon: Icons.check_circle,
              iconColor: Colors.orange,
              title: 'True or False',
              subtitle: 'Simple yes/no question',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTrueFalseScreen(),
                  ),
                );
                if (result != null && result is ActivityModel) {
                  Navigator.pop(context, result);
                }
              },
            ),

            const SizedBox(height: 12),

            // Drag & Drop Card
            _buildActivityTypeCard(
              context: context,
              icon: Icons.swap_horiz,
              iconColor: Colors.purple,
              title: 'Drag & Drop',
              subtitle: 'Match items together',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This screen will be built in the next step!'),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // AI Generated Card
            _buildActivityTypeCard(
              context: context,
              icon: Icons.auto_awesome,
              iconColor: Colors.purple,
              title: 'AI Generated',
              subtitle: 'Generate activities from text using AI',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiGeneratorScreen(),
                  ),
                );
                // Handle result - could be List<ActivityModel> or ActivityResult
                if (result != null) {
                  // Pass the result back as-is (whether it's activities or ActivityResult)
                  Navigator.pop(context, result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTypeCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
              const SizedBox(width: 16),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
