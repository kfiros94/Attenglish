/// Configuration model for AI-powered activity generation
///
/// Defines all parameters needed to generate educational activities
/// using Claude AI, including grade level, difficulty, activity types,
/// and accessibility preferences.
class GenerationConfig {
  /// Student grade level (e.g., "1st", "2nd", "3rd", ... "12th")
  final String gradeLevel;

  /// Difficulty level: "beginner", "intermediate", or "advanced"
  final String difficulty;

  /// Number of multiple choice questions to generate (single answer)
  final int multipleChoiceCount;

  /// Number of multiple answer questions to generate (checkboxes)
  final int multipleAnswerCount;

  /// Number of fill in the blank activities to generate
  final int fillBlankCount;

  /// Number of true/false questions to generate
  final int trueFalseCount;

  /// Number of drag & drop matching activities to generate
  final int dragDropCount;

  /// Number of image description activities to generate
  final int imageDescriptionCount;

  /// Number of cloze (fill-in-the-blank from story) activities to generate
  final int clozeCount;

  /// Number of open-ended reading comprehension questions to generate
  final int openEndedCount;

  /// Language for activities: "english", "hebrew", or "both"
  final String language;

  /// Whether to include vocabulary building exercises
  final bool includeVocabulary;

  /// Whether to make activities ADHD-friendly with clear structure
  /// and appropriate pacing (always true for this app)
  final bool adhdFriendly;

  /// Valid grade levels
  static const List<String> validGradeLevels = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th',
    '11th',
    '12th',
  ];

  /// Valid difficulty levels
  static const List<String> validDifficulties = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  /// Valid language options
  static const List<String> validLanguages = [
    'english',
    'hebrew',
    'both',
  ];

  /// Creates a new generation configuration
  ///
  /// Throws [ArgumentError] if validation fails
  const GenerationConfig({
    required this.gradeLevel,
    required this.difficulty,
    this.multipleChoiceCount = 5,
    this.multipleAnswerCount = 0,
    this.fillBlankCount = 3,
    this.trueFalseCount = 3,
    this.dragDropCount = 2,
    this.imageDescriptionCount = 0,
    this.clozeCount = 0,
    this.openEndedCount = 0,
    this.language = 'english',
    this.includeVocabulary = true,
    this.adhdFriendly = true,
  });

  /// Total number of activities to generate
  int get totalActivities =>
      multipleChoiceCount +
      multipleAnswerCount +
      fillBlankCount +
      trueFalseCount +
      dragDropCount +
      imageDescriptionCount +
      clozeCount +
      openEndedCount;

  /// Validates the configuration
  ///
  /// Throws [ArgumentError] if any validation fails
  void validate() {
    // Validate grade level
    if (!validGradeLevels.contains(gradeLevel)) {
      throw ArgumentError(
        'Invalid grade level: $gradeLevel. '
        'Must be one of: ${validGradeLevels.join(", ")}',
      );
    }

    // Validate difficulty
    if (!validDifficulties.contains(difficulty)) {
      throw ArgumentError(
        'Invalid difficulty: $difficulty. '
        'Must be one of: ${validDifficulties.join(", ")}',
      );
    }

    // Validate language
    if (!validLanguages.contains(language)) {
      throw ArgumentError(
        'Invalid language: $language. '
        'Must be one of: ${validLanguages.join(", ")}',
      );
    }

    // Validate activity counts
    if (multipleChoiceCount < 0) {
      throw ArgumentError(
        'Multiple choice count must be >= 0, got: $multipleChoiceCount',
      );
    }

    if (multipleAnswerCount < 0) {
      throw ArgumentError(
        'Multiple answer count must be >= 0, got: $multipleAnswerCount',
      );
    }

    if (fillBlankCount < 0) {
      throw ArgumentError(
        'Fill blank count must be >= 0, got: $fillBlankCount',
      );
    }

    if (trueFalseCount < 0) {
      throw ArgumentError(
        'True/false count must be >= 0, got: $trueFalseCount',
      );
    }

    if (dragDropCount < 0) {
      throw ArgumentError(
        'Drag & drop count must be >= 0, got: $dragDropCount',
      );
    }

    if (imageDescriptionCount < 0) {
      throw ArgumentError(
        'Image description count must be >= 0, got: $imageDescriptionCount',
      );
    }

    if (clozeCount < 0) {
      throw ArgumentError(
        'Cloze count must be >= 0, got: $clozeCount',
      );
    }

    if (openEndedCount < 0) {
      throw ArgumentError(
        'Open-ended count must be >= 0, got: $openEndedCount',
      );
    }

    // Validate total activities
    if (totalActivities == 0) {
      throw ArgumentError(
        'Total activities must be > 0. At least one activity type must have count > 0',
      );
    }

    if (totalActivities > 50) {
      throw ArgumentError(
        'Total activities ($totalActivities) exceeds maximum of 50',
      );
    }
  }

  /// Converts the configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'gradeLevel': gradeLevel,
      'difficulty': difficulty,
      'activityCounts': {
        'multipleChoice': multipleChoiceCount,
        'multipleAnswer': multipleAnswerCount,
        'fillBlank': fillBlankCount,
        'trueFalse': trueFalseCount,
        'dragDrop': dragDropCount,
        'imageDescription': imageDescriptionCount,
        'cloze': clozeCount,
        'openEnded': openEndedCount,
      },
      'language': language,
      'includeVocabulary': includeVocabulary,
      'adhdFriendly': adhdFriendly,
    };
  }

  /// Creates a configuration from JSON
  ///
  /// Example:
  /// ```dart
  /// final config = GenerationConfig.fromJson({
  ///   'gradeLevel': '5th',
  ///   'difficulty': 'intermediate',
  ///   'activityCounts': {
  ///     'multipleChoice': 5,
  ///     'fillBlank': 3,
  ///     'trueFalse': 3,
  ///     'dragDrop': 2,
  ///   },
  ///   'language': 'english',
  ///   'includeVocabulary': true,
  ///   'adhdFriendly': true,
  /// });
  /// ```
  factory GenerationConfig.fromJson(Map<String, dynamic> json) {
    final activityCounts = json['activityCounts'] as Map<String, dynamic>? ?? {};

    return GenerationConfig(
      gradeLevel: json['gradeLevel'] as String? ?? '5th',
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      multipleChoiceCount: activityCounts['multipleChoice'] as int? ?? 5,
      multipleAnswerCount: activityCounts['multipleAnswer'] as int? ?? 0,
      fillBlankCount: activityCounts['fillBlank'] as int? ?? 3,
      trueFalseCount: activityCounts['trueFalse'] as int? ?? 3,
      dragDropCount: activityCounts['dragDrop'] as int? ?? 2,
      imageDescriptionCount: activityCounts['imageDescription'] as int? ?? 0,
      clozeCount: activityCounts['cloze'] as int? ?? 0,
      openEndedCount: activityCounts['openEnded'] as int? ?? 0,
      language: json['language'] as String? ?? 'english',
      includeVocabulary: json['includeVocabulary'] as bool? ?? true,
      adhdFriendly: json['adhdFriendly'] as bool? ?? true,
    );
  }

  /// Creates a copy of this configuration with updated fields
  ///
  /// Example:
  /// ```dart
  /// final newConfig = config.copyWith(
  ///   difficulty: 'advanced',
  ///   multipleChoiceCount: 10,
  /// );
  /// ```
  GenerationConfig copyWith({
    String? gradeLevel,
    String? difficulty,
    int? multipleChoiceCount,
    int? multipleAnswerCount,
    int? fillBlankCount,
    int? trueFalseCount,
    int? dragDropCount,
    int? imageDescriptionCount,
    int? clozeCount,
    int? openEndedCount,
    String? language,
    bool? includeVocabulary,
    bool? adhdFriendly,
  }) {
    return GenerationConfig(
      gradeLevel: gradeLevel ?? this.gradeLevel,
      difficulty: difficulty ?? this.difficulty,
      multipleChoiceCount: multipleChoiceCount ?? this.multipleChoiceCount,
      multipleAnswerCount: multipleAnswerCount ?? this.multipleAnswerCount,
      fillBlankCount: fillBlankCount ?? this.fillBlankCount,
      trueFalseCount: trueFalseCount ?? this.trueFalseCount,
      dragDropCount: dragDropCount ?? this.dragDropCount,
      imageDescriptionCount: imageDescriptionCount ?? this.imageDescriptionCount,
      clozeCount: clozeCount ?? this.clozeCount,
      openEndedCount: openEndedCount ?? this.openEndedCount,
      language: language ?? this.language,
      includeVocabulary: includeVocabulary ?? this.includeVocabulary,
      adhdFriendly: adhdFriendly ?? this.adhdFriendly,
    );
  }

  /// Creates a default configuration for quick testing
  ///
  /// Defaults:
  /// - Grade level: 5th
  /// - Difficulty: intermediate
  /// - 5 multiple choice, 3 fill blank, 3 true/false, 2 drag & drop
  /// - English language
  /// - Vocabulary included
  /// - ADHD-friendly enabled
  factory GenerationConfig.defaultConfig() {
    return const GenerationConfig(
      gradeLevel: '5th',
      difficulty: 'intermediate',
      multipleChoiceCount: 5,
      fillBlankCount: 3,
      trueFalseCount: 3,
      dragDropCount: 2,
      language: 'english',
      includeVocabulary: true,
      adhdFriendly: true,
    );
  }

  /// Creates a minimal configuration with only multiple choice questions
  ///
  /// Useful for testing or when you only need one activity type
  factory GenerationConfig.minimal({
    String gradeLevel = '5th',
    String difficulty = 'beginner',
    int questionCount = 3,
  }) {
    return GenerationConfig(
      gradeLevel: gradeLevel,
      difficulty: difficulty,
      multipleChoiceCount: questionCount,
      fillBlankCount: 0,
      trueFalseCount: 0,
      dragDropCount: 0,
    );
  }

  @override
  String toString() {
    return 'GenerationConfig('
        'gradeLevel: $gradeLevel, '
        'difficulty: $difficulty, '
        'totalActivities: $totalActivities, '
        'language: $language'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GenerationConfig &&
        other.gradeLevel == gradeLevel &&
        other.difficulty == difficulty &&
        other.multipleChoiceCount == multipleChoiceCount &&
        other.multipleAnswerCount == multipleAnswerCount &&
        other.fillBlankCount == fillBlankCount &&
        other.trueFalseCount == trueFalseCount &&
        other.dragDropCount == dragDropCount &&
        other.imageDescriptionCount == imageDescriptionCount &&
        other.clozeCount == clozeCount &&
        other.openEndedCount == openEndedCount &&
        other.language == language &&
        other.includeVocabulary == includeVocabulary &&
        other.adhdFriendly == adhdFriendly;
  }

  @override
  int get hashCode {
    return Object.hash(
      gradeLevel,
      difficulty,
      multipleChoiceCount,
      multipleAnswerCount,
      fillBlankCount,
      trueFalseCount,
      dragDropCount,
      imageDescriptionCount,
      clozeCount,
      openEndedCount,
      language,
      includeVocabulary,
      adhdFriendly,
    );
  }
}
