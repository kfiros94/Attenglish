import '../models/generation_config_model.dart';
import '../../../core/utils/validation_result.dart';

/// Service for building and validating prompts for Claude AI
///
/// This service handles:
/// - Validating source text before sending to API
/// - Building detailed, structured prompts for activity generation
/// - Ensuring prompts follow ADHD-friendly educational principles
class PromptBuilderService {
  // Private constructor to prevent instantiation
  PromptBuilderService._();

  /// Validates source text before generating activities
  ///
  /// Checks:
  /// - Text is not empty
  /// - Text has at least 50 words (minimum for meaningful activities)
  /// - Text does not exceed 5000 words (API limits and performance)
  ///
  /// Returns [ValidationResult] with success or error message
  ///
  /// Example:
  /// ```dart
  /// final result = PromptBuilderService.validateSourceText(myText);
  /// if (result.isError) {
  ///   print('Validation failed: ${result.message}');
  ///   return;
  /// }
  /// ```
  static ValidationResult validateSourceText(String text) {
    // Trim whitespace
    final trimmedText = text.trim();

    // Check if empty
    if (trimmedText.isEmpty) {
      return ValidationResult.error('Please provide some text');
    }

    // Count words
    final wordCount = trimmedText.split(RegExp(r'\s+')).length;

    // Check minimum word count
    if (wordCount < 50) {
      return ValidationResult.error(
        'Text is too short. Need at least 50 words, but got $wordCount words.',
      );
    }

    // Check maximum word count
    if (wordCount > 5000) {
      return ValidationResult.error(
        'Text is too long. Maximum 5000 words allowed, but got $wordCount words.',
      );
    }

    // Valid
    return ValidationResult.success('Text is valid ($wordCount words)');
  }

  /// Builds a detailed prompt for Claude AI to generate learning activities
  ///
  /// The prompt includes:
  /// - ADHD-friendly educational principles
  /// - Source text to base activities on
  /// - Activity type breakdown with counts
  /// - Difficulty and grade level specifications
  /// - Important rules for question creation
  /// - Optional vocabulary extraction
  /// - JSON output format specification
  ///
  /// Parameters:
  /// - [sourceText]: The text content to generate activities from
  /// - [config]: Configuration specifying what types and how many activities to generate
  ///
  /// Returns a complete prompt string ready to send to Claude API
  ///
  /// Example:
  /// ```dart
  /// final config = GenerationConfig.defaultConfig();
  /// final prompt = PromptBuilderService.buildActivityGenerationPrompt(
  ///   'The cat sat on the mat...',
  ///   config,
  /// );
  /// ```
  static String buildActivityGenerationPrompt({
    required String sourceText,
    required GenerationConfig config,
  }) {
    return '''
You are an expert English teacher creating learning activities for Hebrew-speaking students aged 7-12 with ADHD.

CRITICAL REQUIREMENTS FOR ADHD LEARNERS:
- Use simple, clear, and unambiguous language
- Keep questions concise (maximum 2 sentences)
- Avoid complex sentence structures
- Use concrete examples, not abstract concepts
- Make instructions explicit and direct
- Ensure ONE clear correct answer per question
- Avoid confusing or tricky distractors

SOURCE TEXT:
"""
${sourceText.trim()}
"""

TASK:
Generate ${config.totalActivities} English learning activities based ONLY on the source text above.

ACTIVITY BREAKDOWN:
1. Multiple Choice: ${config.multipleChoiceCount} questions (4 options each)
2. Fill in the Blank: ${config.fillBlankCount} questions
3. True/False: ${config.trueFalseCount} questions
4. Drag & Drop (Matching): ${config.dragDropCount} questions

DIFFICULTY LEVEL: ${config.difficulty.toUpperCase()}
- Beginner: Basic vocabulary, simple sentences, obvious answers
- Intermediate: Moderate vocabulary, some inference needed
- Advanced: Complex vocabulary, deeper comprehension required

TARGET GRADE: ${config.gradeLevel} grade (adjust complexity accordingly)

IMPORTANT RULES:
1. ALL questions MUST be answerable from the source text - no external information
2. For Multiple Choice:
   - Provide exactly 4 options
   - Only ONE correct answer
   - Make distractors plausible but clearly wrong
   - Avoid "all of the above" or "none of the above"

3. For Fill in the Blank:
   - Use ___ to indicate the blank
   - The context should make the answer clear
   - Accept minor variations (plurals, tenses)

4. For True/False:
   - Statement must be clearly true or false based on text
   - No ambiguity allowed

5. For Drag & Drop (Matching):
   - Provide 3-4 items to match
   - Clear one-to-one correspondence
   - Example: Match animals to sounds, words to definitions

${config.includeVocabulary ? '''
6. VOCABULARY EXTRACTION:
   - Extract 8-10 key vocabulary words from the text
   - Provide simple definition (one sentence, grade-appropriate)
   - Include Hebrew translation
   - Example sentence using the word
''' : ''}

OUTPUT FORMAT (CRITICAL):
Respond with ONLY valid JSON. No markdown, no code blocks, no explanations.

{
  "activities": [
    {
      "type": "multiple_choice",
      "question": "Your question here?",
      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
      "correctAnswerIndex": 0,
      "points": 10
    },
    {
      "type": "fill_blank",
      "question": "The cat sat on the ___.",
      "correctAnswers": ["mat", "floor"],
      "caseSensitive": false,
      "points": 10
    },
    {
      "type": "true_false",
      "question": "The sky is blue.",
      "correctAnswer": true,
      "points": 5
    },
    {
      "type": "drag_drop",
      "question": "Match the animals to their sounds:",
      "leftItems": ["Dog", "Cat", "Cow"],
      "rightItems": ["Bark", "Meow", "Moo"],
      "correctPairs": {"0": 0, "1": 1, "2": 2},
      "points": 15
    }
  ],
  "vocabulary": [
    {
      "word": "example",
      "definition": "Something that shows what something else is like",
      "hebrew": "דוגמה",
      "exampleSentence": "The teacher gave an example of a noun."
    }
  ],
  "summary": "Brief 2-3 sentence summary of what students will learn from these activities."
}

GENERATE ACTIVITIES NOW:
''';
  }

  /// Extracts age range from grade level
  ///
  /// Converts grade level (e.g., "3rd") to approximate age range.
  /// Formula: grade number + 5 to grade number + 6
  ///
  /// Examples:
  /// - "1st" -> "6-7"
  /// - "5th" -> "10-11"
  /// - "12th" -> "17-18"
  ///
  /// Returns "7-12" as default if grade cannot be parsed
  ///
  /// Parameters:
  /// - [gradeLevel]: Grade level string (e.g., "1st", "5th", "12th")
  ///
  /// Returns age range string
  static String _getAgeRange(String gradeLevel) {
    try {
      // Extract the numeric part from grade level
      // Handles "1st", "2nd", "3rd", "4th", etc.
      final match = RegExp(r'(\d+)').firstMatch(gradeLevel);

      if (match != null) {
        final gradeNum = int.parse(match.group(1)!);
        final minAge = gradeNum + 5;
        final maxAge = gradeNum + 6;
        return '$minAge-$maxAge';
      }
    } catch (e) {
      // If parsing fails, return default
    }

    // Default fallback
    return '7-12';
  }
}
