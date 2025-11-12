import '../../lessons/models/activity_model.dart';

/// Represents a vocabulary item extracted by AI
///
/// Contains the word, its definition, optional Hebrew translation,
/// and an example sentence showing usage.
class VocabularyItem {
  /// The vocabulary word
  final String word;

  /// Simple definition appropriate for the target grade level
  final String definition;

  /// Hebrew translation (optional)
  final String? hebrew;

  /// Example sentence using the word (optional)
  final String? exampleSentence;

  /// Creates a new vocabulary item
  const VocabularyItem({
    required this.word,
    required this.definition,
    this.hebrew,
    this.exampleSentence,
  });

  /// Creates a vocabulary item from JSON
  ///
  /// Example:
  /// ```dart
  /// final item = VocabularyItem.fromJson({
  ///   'word': 'example',
  ///   'definition': 'Something that shows what something else is like',
  ///   'hebrew': 'דוגמה',
  ///   'exampleSentence': 'The teacher gave an example of a noun.'
  /// });
  /// ```
  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      word: json['word'] as String,
      definition: json['definition'] as String,
      hebrew: json['hebrew'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
    );
  }

  /// Converts the vocabulary item to JSON
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'definition': definition,
      if (hebrew != null) 'hebrew': hebrew,
      if (exampleSentence != null) 'exampleSentence': exampleSentence,
    };
  }

  /// Creates a copy with updated fields
  VocabularyItem copyWith({
    String? word,
    String? definition,
    String? hebrew,
    String? exampleSentence,
  }) {
    return VocabularyItem(
      word: word ?? this.word,
      definition: definition ?? this.definition,
      hebrew: hebrew ?? this.hebrew,
      exampleSentence: exampleSentence ?? this.exampleSentence,
    );
  }

  @override
  String toString() {
    return 'VocabularyItem(word: $word, definition: $definition, hebrew: $hebrew)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VocabularyItem &&
        other.word == word &&
        other.definition == definition &&
        other.hebrew == hebrew &&
        other.exampleSentence == exampleSentence;
  }

  @override
  int get hashCode {
    return Object.hash(
      word,
      definition,
      hebrew,
      exampleSentence,
    );
  }
}

/// Response from AI generation containing activities, vocabulary, and metadata
///
/// This class encapsulates the complete response from Claude API
/// after generating learning activities, including timing information
/// and metadata for tracking and debugging.
class AiGenerationResponse {
  /// Generated activities ready to use
  final List<ActivityModel> activities;

  /// Extracted vocabulary words with definitions
  final List<VocabularyItem> vocabulary;

  /// Brief summary of what students will learn
  final String summary;

  /// Total number of activities generated
  final int totalActivities;

  /// Time taken to generate the response
  final Duration generationTime;

  /// Additional metadata about the generation
  final Map<String, dynamic> metadata;

  /// The original source text used to generate activities
  final String sourceText;

  /// Creates a new AI generation response
  const AiGenerationResponse({
    required this.activities,
    required this.vocabulary,
    required this.summary,
    required this.totalActivities,
    required this.generationTime,
    required this.metadata,
    required this.sourceText,
  });

  /// Creates a response from Claude API JSON
  ///
  /// Parses the JSON response from Claude and converts it into
  /// a structured response object with activities and vocabulary.
  ///
  /// Parameters:
  /// - [json]: The JSON response from Claude API
  /// - [generationTime]: How long the API call took
  ///
  /// Example:
  /// ```dart
  /// final stopwatch = Stopwatch()..start();
  /// final apiResponse = await callClaudeApi();
  /// stopwatch.stop();
  ///
  /// final response = AiGenerationResponse.fromJson(
  ///   jsonDecode(apiResponse),
  ///   stopwatch.elapsed,
  /// );
  /// ```
  factory AiGenerationResponse.fromJson(
    Map<String, dynamic> json,
    Duration generationTime,
    String sourceText,
  ) {
    // Parse activities
    final activitiesJson = json['activities'] as List<dynamic>? ?? [];
    final activities = activitiesJson
        .map((activityJson) =>
            ActivityModel.fromJson(activityJson as Map<String, dynamic>))
        .toList();

    // Parse vocabulary
    final vocabularyJson = json['vocabulary'] as List<dynamic>? ?? [];
    final vocabulary = vocabularyJson
        .map((vocabJson) =>
            VocabularyItem.fromJson(vocabJson as Map<String, dynamic>))
        .toList();

    // Extract summary
    final summary = json['summary'] as String? ?? '';

    // Create metadata
    final metadata = <String, dynamic>{
      'model': 'claude-sonnet-4-20250514',
      'timestamp': DateTime.now().toIso8601String(),
      'success': true,
    };

    return AiGenerationResponse(
      activities: activities,
      vocabulary: vocabulary,
      summary: summary,
      totalActivities: activities.length,
      generationTime: generationTime,
      metadata: metadata,
      sourceText: sourceText,
    );
  }

  /// Converts the response to JSON
  ///
  /// Useful for logging, storage, or debugging purposes.
  Map<String, dynamic> toJson() {
    return {
      'activities': activities.map((a) => a.toJson()).toList(),
      'vocabulary': vocabulary.map((v) => v.toJson()).toList(),
      'summary': summary,
      'totalActivities': totalActivities,
      'generationTime': generationTime.inMilliseconds,
      'metadata': metadata,
    };
  }

  /// Whether vocabulary was extracted
  bool get hasVocabulary => vocabulary.isNotEmpty;

  /// Total points available across all activities
  ///
  /// Sums up the points from all generated activities
  int get totalPoints {
    return activities.fold<int>(
      0,
      (sum, activity) => sum + activity.points,
    );
  }

  @override
  String toString() {
    return 'AiGenerationResponse('
        'activities: ${activities.length}, '
        'vocabulary: ${vocabulary.length}, '
        'totalPoints: $totalPoints, '
        'generationTime: ${generationTime.inSeconds}s'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AiGenerationResponse &&
        other.activities.length == activities.length &&
        other.vocabulary.length == vocabulary.length &&
        other.summary == summary &&
        other.totalActivities == totalActivities &&
        other.generationTime == generationTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      activities.length,
      vocabulary.length,
      summary,
      totalActivities,
      generationTime,
    );
  }
}
