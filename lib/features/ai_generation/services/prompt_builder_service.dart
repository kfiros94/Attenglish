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

TARGET GRADE: ${config.gradeLevel}
${_getGradeSpecificGuidelines(config.gradeLevel, config.difficulty)}

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

  /// Generates grade-specific guidelines for question difficulty
  ///
  /// For grades 1-9: Uses grade number to determine age-appropriate complexity
  /// For grades 10-12: Uses teacher-selected difficulty level
  ///
  /// Returns detailed guidelines for the AI to create appropriate questions
  static String _getGradeSpecificGuidelines(String gradeLevel, String difficulty) {
    final gradeNum = int.tryParse(gradeLevel.replaceAll(RegExp(r'\D'), '')) ?? 5;

    if (gradeNum >= 1 && gradeNum <= 9) {
      // Grades 1-9: Grade-appropriate difficulty
      return _getElementaryMiddleSchoolGuidelines(gradeNum);
    } else {
      // Grades 10-12: Teacher-selected difficulty
      return _getHighSchoolGuidelines(difficulty);
    }
  }

  /// Elementary and middle school (grades 1-9) guidelines
  static String _getElementaryMiddleSchoolGuidelines(int grade) {
    switch (grade) {
      case 1:
        return '''
GRADE 1 LEVEL (Ages 6-7):
- Use VERY simple vocabulary (cat, dog, run, happy, big, etc.)
- Questions should be about basic facts clearly stated in the text
- Sentences should be 3-5 words maximum
- Use present simple tense only
- Multiple choice: 1-2 word options
- Fill in the blank: Single, obvious word (colors, animals, numbers)
- Example: "The cat is ___." (Answer: "big" from text "The big cat")
- No inference needed - everything must be DIRECTLY in the text''';

      case 2:
        return '''
GRADE 2 LEVEL (Ages 7-8):
- Simple vocabulary (100-200 most common English words)
- Questions about obvious facts and simple descriptions
- Sentences should be 4-7 words
- Use present simple and simple past
- Multiple choice: Short phrases (2-3 words)
- Fill in the blank: Common words for objects, actions, descriptions
- Example: "What color was the dog?" (Answer directly in text)
- Minimal inference - 90% direct from text''';

      case 3:
        return '''
GRADE 3 LEVEL (Ages 8-9):
- Elementary vocabulary (300-400 common words)
- Questions about main ideas and simple sequence
- Sentences should be 5-10 words
- Use present, past, and simple future
- Multiple choice: Simple sentences
- Can ask "Why?" questions if answer is clearly in text
- Example: "Why did the boy run home?" (Because text says "ran home to eat dinner")
- Some simple inference allowed if very obvious''';

      case 4:
        return '''
GRADE 4 LEVEL (Ages 9-10):
- Growing vocabulary (500-600 words)
- Questions about main ideas, details, and basic cause/effect
- Sentences should be 6-12 words
- Can use various tenses appropriately
- Introduce basic adjectives and adverbs
- Multiple choice: Full sentences with simple vocabulary
- Can ask about character feelings if explicitly stated
- Example: "How did Sarah feel when she won?" (Text says "Sarah was happy when she won")''';

      case 5:
        return '''
GRADE 5 LEVEL (Ages 10-11):
- Intermediate vocabulary (700-900 words)
- Questions about themes, inferences, and relationships
- Sentences should be 7-15 words
- Can include phrasal verbs (give up, look for, etc.)
- Questions can require simple inference from context
- Multiple choice: Options can be similar, requiring careful reading
- Can ask about implied meanings if fairly obvious
- Example: "What can you infer about the character?" (based on described actions)''';

      case 6:
        return '''
GRADE 6 LEVEL (Ages 11-12):
- Age-appropriate vocabulary (1000-1200 words)
- Questions about analysis, comparison, and deeper comprehension
- Sentences should be 8-18 words
- Can use more complex grammar (conditionals, passive voice)
- Questions require some inference and critical thinking
- Multiple choice: Nuanced options requiring careful analysis
- Can ask about author's purpose and text structure
- Example: "Why did the author use this example?" (analyzing text structure)''';

      case 7:
        return '''
GRADE 7 LEVEL (Ages 12-13):
- Expanded vocabulary (1300-1600 words)
- Questions about literary devices, tone, and implicit meanings
- Sentences should be 10-20 words
- Complex grammar structures expected
- Questions require inference, analysis, and evaluation
- Multiple choice: Similar options requiring deep understanding
- Can ask about symbolism and figurative language
- Example: "What does this metaphor suggest about the theme?"''';

      case 8:
        return '''
GRADE 8 LEVEL (Ages 13-14):
- Advanced vocabulary (1700-2000 words)
- Questions about complex themes, arguments, and perspectives
- Sentences should be 12-25 words
- Advanced grammar and varied sentence structures
- Questions require synthesis and evaluation
- Multiple choice: Sophisticated options testing deep comprehension
- Can analyze author's craft and rhetorical devices
- Example: "How does the author's choice of words affect the tone?"''';

      case 9:
        return '''
GRADE 9 LEVEL (Ages 14-15):
- Pre-high school vocabulary (2000-2500 words)
- Questions about complex analysis, synthesis, and evaluation
- Sentences can be 15-30 words with complex structures
- Academic language and formal register
- Questions require critical thinking and textual evidence
- Multiple choice: Nuanced options requiring careful textual analysis
- Can analyze multiple perspectives and implicit arguments
- Example: "Analyze how the author develops the central argument through..."''';

      default:
        return '''
INTERMEDIATE LEVEL:
- Age-appropriate vocabulary
- Mix of literal and inferential questions
- Clear, well-structured sentences
- Questions appropriate for middle school students''';
    }
  }

  /// High school (grades 10-12) difficulty guidelines
  static String _getHighSchoolGuidelines(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return '''
HIGH SCHOOL - NORMAL DIFFICULTY:
- Standard high school vocabulary (2500-3000 words)
- Questions test comprehension, basic analysis, and interpretation
- Mix of literal and inferential questions
- Sentences should be clear and well-structured (15-25 words)
- Multiple choice: Options require careful reading and understanding
- Focus on main ideas, supporting details, and basic literary analysis
- Example: "What is the main argument presented in this passage?"
- Suitable for grade 10 or students who need reinforcement''';

      case 'intermediate':
      case 'hard':
        return '''
HIGH SCHOOL - HARD DIFFICULTY:
- Advanced vocabulary (3000-4000 words)
- Questions require deep analysis, synthesis, and evaluation
- Complex inferential and evaluative questions
- Sophisticated sentence structures (20-35 words)
- Multiple choice: Nuanced options testing critical thinking
- Analyze rhetorical strategies, complex themes, and textual relationships
- Example: "Evaluate the effectiveness of the author's use of..."
- Suitable for grade 11 or advanced students''';

      case 'advanced':
      case 'very hard':
        return '''
HIGH SCHOOL - VERY HARD DIFFICULTY:
- College-prep vocabulary (4000+ words)
- Questions demand critical analysis, synthesis across texts, and evaluation
- Highly complex analytical and evaluative questions
- Advanced academic writing style (25-40 words)
- Multiple choice: Sophisticated options requiring expert-level analysis
- Analyze implicit arguments, multiple perspectives, and rhetorical complexity
- Compare and contrast themes across different sections
- Example: "Synthesize the author's implicit assumptions about..."
- Suitable for grade 12, AP level, or college-prep students''';

      default:
        return '''
HIGH SCHOOL LEVEL:
- Advanced vocabulary and complex sentence structures
- Questions require analysis, synthesis, and evaluation
- Mix of comprehension and critical thinking questions''';
    }
  }
}
