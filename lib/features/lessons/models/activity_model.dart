/// Activity/Exercise model for lessons
/// Supports multiple types: multiple choice, fill blank, drag & drop, true/false
class ActivityModel {
  final String id;
  final String type; // 'multiple_choice', 'fill_blank', 'true_false', 'drag_drop'
  final String question;
  final String? instructions; // optional helper text

  // For multiple choice (4 options):
  final List<String>? options; // ["Red", "Blue", "Green", "Yellow"]
  final int? correctAnswerIndex; // 0-3 (which option is correct) - single answer
  final List<int>? correctAnswerIndices; // [0, 2] (multiple correct answers)

  // For fill in blank:
  final String? blankSentence; // "The cat is _____ the table"
  final String? correctWord; // "on"

  // For drag & drop (match pairs):
  final List<String>? leftItems; // ["cat", "dog", "bird"]
  final List<String>? rightItems; // ["meow", "woof", "tweet"]
  final Map<String, String>? correctPairs; // {"cat": "meow", "dog": "woof"}

  // For true/false:
  final bool? correctAnswer; // true or false

  final int points; // points awarded for correct answer

  const ActivityModel({
    required this.id,
    required this.type,
    required this.question,
    this.instructions,
    this.options,
    this.correctAnswerIndex,
    this.correctAnswerIndices,
    this.blankSentence,
    this.correctWord,
    this.leftItems,
    this.rightItems,
    this.correctPairs,
    this.correctAnswer,
    this.points = 10,
  });

  /// Create ActivityModel from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      type: json['type'] as String,
      question: json['question'] as String,
      instructions: json['instructions'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      correctAnswerIndex: json['correctAnswerIndex'] as int?,
      correctAnswerIndices: (json['correctAnswerIndices'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      blankSentence: json['blankSentence'] as String?,
      correctWord: json['correctWord'] as String?,
      leftItems: (json['leftItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rightItems: (json['rightItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      correctPairs: json['correctPairs'] != null
          ? Map<String, String>.from(json['correctPairs'] as Map)
          : null,
      correctAnswer: json['correctAnswer'] as bool?,
      points: json['points'] as int? ?? 10,
    );
  }

  /// Convert ActivityModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question': question,
      if (instructions != null) 'instructions': instructions,
      if (options != null) 'options': options,
      if (correctAnswerIndex != null) 'correctAnswerIndex': correctAnswerIndex,
      if (correctAnswerIndices != null) 'correctAnswerIndices': correctAnswerIndices,
      if (blankSentence != null) 'blankSentence': blankSentence,
      if (correctWord != null) 'correctWord': correctWord,
      if (leftItems != null) 'leftItems': leftItems,
      if (rightItems != null) 'rightItems': rightItems,
      if (correctPairs != null) 'correctPairs': correctPairs,
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      'points': points,
    };
  }

  /// Create a copy with modified fields
  ActivityModel copyWith({
    String? id,
    String? type,
    String? question,
    String? instructions,
    List<String>? options,
    int? correctAnswerIndex,
    List<int>? correctAnswerIndices,
    String? blankSentence,
    String? correctWord,
    List<String>? leftItems,
    List<String>? rightItems,
    Map<String, String>? correctPairs,
    bool? correctAnswer,
    int? points,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      type: type ?? this.type,
      question: question ?? this.question,
      instructions: instructions ?? this.instructions,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      correctAnswerIndices: correctAnswerIndices ?? this.correctAnswerIndices,
      blankSentence: blankSentence ?? this.blankSentence,
      correctWord: correctWord ?? this.correctWord,
      leftItems: leftItems ?? this.leftItems,
      rightItems: rightItems ?? this.rightItems,
      correctPairs: correctPairs ?? this.correctPairs,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      points: points ?? this.points,
    );
  }

  /// Get activity type label
  String get typeLabel {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'drag_drop':
        return 'Drag & Drop';
      case 'true_false':
        return 'True/False';
      default:
        return 'Unknown';
    }
  }

  /// Get activity type icon
  String get typeIcon {
    switch (type) {
      case 'multiple_choice':
        return '📝';
      case 'fill_blank':
        return '✏️';
      case 'drag_drop':
        return '🔄';
      case 'true_false':
        return '🎯';
      default:
        return '❓';
    }
  }
}
