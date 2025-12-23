import '../../../core/config/ai_config.dart';
import '../models/generation_config_model.dart';
import './claude_ai_service.dart';

/// Test function to verify AI generation service is working correctly
///
/// This function:
/// 1. Checks API key configuration
/// 2. Creates a ClaudeAiService instance
/// 3. Sets up a simple test configuration
/// 4. Generates activities from sample text about cats
/// 5. Displays the results
///
/// Usage:
/// ```dart
/// // In main.dart or a test screen:
/// await testAiGeneration();
/// ```
///
/// Or add a button in your app:
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     await testAiGeneration();
///   },
///   child: Text('Test AI Generation'),
/// )
/// ```
Future<void> testAiGeneration() async {
  print('🧪 Testing AI Generation Service...\n');

  try {
    // 1. Check API key configuration
    print('1. Checking API configuration...');
    if (!AiConfig.isConfigured) {
      print('❌ API key not configured');
      print('   Please set ANTHROPIC_API_KEY in environment');
      return;
    }
    print('✅ API key configured\n');

    // 2. Create service
    print('2. Creating AI service...');
    final service = ClaudeAiService.withDefaultKey();
    print('✅ Service created\n');

    // 3. Create test config
    print('3. Setting up test configuration...');
    final config = GenerationConfig(
      gradeLevel: '3rd',
      difficulty: 'beginner',
      multipleChoiceCount: 2,
      fillBlankCount: 1,
      trueFalseCount: 1,
      dragDropCount: 0,
    );
    print('✅ Config created');
    print('   Grade: ${config.gradeLevel}');
    print('   Difficulty: ${config.difficulty}');
    print('   Total activities: ${config.totalActivities}\n');

    // 4. Test with sample text
    print('4. Generating activities from sample text...');
    const sampleText = '''
    The cat is a small animal. Cats have four legs and a tail.
    Most cats like to play and sleep. Cats can be many different colors
    like black, white, orange, or gray. Cats say "meow" when they want food or attention.
    Many people have cats as pets because they are cute and friendly.
    ''';

    final wordCount = sampleText.split(RegExp(r'\s+')).length;
    print('   Source text: $wordCount words');
    print('   Calling Claude API...');

    final response = await service.generateActivities(
      sourceText: sampleText,
      config: config,
    );

    // 5. Display results
    print('\n✅ Generation successful!\n');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 RESULTS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Activities generated: ${response.totalActivities}');
    print('Vocabulary words: ${response.vocabulary.length}');
    print('Total points: ${response.totalPoints}');
    print('Generation time: ${response.generationTime.inSeconds}.${response.generationTime.inMilliseconds % 1000}s');
    print('Summary: ${response.summary}\n');

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 ACTIVITIES');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (int i = 0; i < response.activities.length; i++) {
      final activity = response.activities[i];
      print('${i + 1}. [${activity.type.toUpperCase()}] (${activity.points} pts)');
      print('   Question: ${activity.question}');

      // Show type-specific details
      if (activity.type == 'multiple_choice' && activity.options != null) {
        for (int j = 0; j < activity.options!.length; j++) {
          final isCorrect = activity.correctAnswerIndices != null
              ? activity.correctAnswerIndices!.contains(j)
              : j == activity.correctAnswerIndex;
          final marker = isCorrect ? '✓' : ' ';
          print('   $marker ${String.fromCharCode(65 + j)}. ${activity.options![j]}');
        }
      } else if (activity.type == 'fill_blank') {
        print('   Answer: ${activity.correctWord}');
      } else if (activity.type == 'true_false') {
        print('   Answer: ${activity.correctAnswer == true ? 'TRUE' : 'FALSE'}');
      }
      print('');
    }

    if (response.vocabulary.isNotEmpty) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📚 VOCABULARY');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      for (var vocab in response.vocabulary) {
        print('• ${vocab.word}');
        print('  Definition: ${vocab.definition}');
        if (vocab.hebrew != null) {
          print('  Hebrew: ${vocab.hebrew}');
        }
        if (vocab.exampleSentence != null) {
          print('  Example: ${vocab.exampleSentence}');
        }
        print('');
      }
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ ALL TESTS PASSED!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Clean up
    service.dispose();
  } on AiGenerationException catch (e) {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('❌ AI GENERATION ERROR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Message: ${e.message}');
    if (e.originalError != null) {
      print('Original error: ${e.originalError}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  } catch (e, stackTrace) {
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('❌ UNEXPECTED ERROR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Error: $e');
    print('\nStack trace:');
    print(stackTrace);
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
}

/// Test function with custom parameters
///
/// Allows testing with different configurations and source text
///
/// Example:
/// ```dart
/// await testAiGenerationCustom(
///   gradeLevel: '5th',
///   difficulty: 'intermediate',
///   sourceText: 'Your custom text here...',
/// );
/// ```
Future<void> testAiGenerationCustom({
  String gradeLevel = '3rd',
  String difficulty = 'beginner',
  int multipleChoiceCount = 2,
  int fillBlankCount = 1,
  int trueFalseCount = 1,
  int dragDropCount = 0,
  required String sourceText,
}) async {
  print('🧪 Testing AI Generation Service (Custom)...\n');

  try {
    // Check API key
    if (!AiConfig.isConfigured) {
      print('❌ API key not configured');
      return;
    }

    // Create service
    final service = ClaudeAiService.withDefaultKey();

    // Create config
    final config = GenerationConfig(
      gradeLevel: gradeLevel,
      difficulty: difficulty,
      multipleChoiceCount: multipleChoiceCount,
      fillBlankCount: fillBlankCount,
      trueFalseCount: trueFalseCount,
      dragDropCount: dragDropCount,
    );

    print('Configuration:');
    print('   Grade: ${config.gradeLevel}');
    print('   Difficulty: ${config.difficulty}');
    print('   Total activities: ${config.totalActivities}');
    print('   Source text: ${sourceText.split(RegExp(r'\s+')).length} words\n');

    print('Generating activities...');
    final response = await service.generateActivities(
      sourceText: sourceText,
      config: config,
    );

    print('✅ Generated ${response.totalActivities} activities in ${response.generationTime.inSeconds}s');
    print('   Total points: ${response.totalPoints}');
    print('   Vocabulary: ${response.vocabulary.length} words\n');

    service.dispose();
  } on AiGenerationException catch (e) {
    print('❌ Error: ${e.message}');
  } catch (e) {
    print('❌ Unexpected error: $e');
  }
}
