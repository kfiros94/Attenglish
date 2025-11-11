/// Standalone test for AI generation service
///
/// Run this with: flutter test test/ai_generation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:attenglish/features/ai_generation/services/test_ai_service.dart';

void main() {
  test('Test AI Generation Service', () async {
    print('\n========================================');
    print('Starting AI Generation Test');
    print('========================================\n');

    await testAiGeneration();

    print('\n========================================');
    print('Test completed successfully!');
    print('========================================\n');
  });
}
