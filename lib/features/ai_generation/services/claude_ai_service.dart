import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/ai_config.dart';
import '../../lessons/models/activity_model.dart';
import '../models/generation_config_model.dart';
import '../models/ai_response_model.dart';
import './prompt_builder_service.dart';

/// Service for interacting with Claude AI API to generate learning activities
///
/// This service handles:
/// - Authentication with Claude API
/// - Building prompts for activity generation
/// - Making API requests
/// - Parsing and validating responses
/// - Error handling and timeout management
///
/// Example usage:
/// ```dart
/// final service = ClaudeAiService.withDefaultKey();
/// try {
///   final response = await service.generateActivities(
///     sourceText: 'The cat sat on the mat...',
///     config: GenerationConfig.defaultConfig(),
///   );
///   print('Generated ${response.activities.length} activities');
/// } catch (e) {
///   print('Error: $e');
/// } finally {
///   service.dispose();
/// }
/// ```
class ClaudeAiService {
  /// Anthropic API key for authentication
  final String apiKey;

  /// HTTP client for making requests (can be injected for testing)
  final http.Client _client;

  /// Creates a new Claude AI service
  ///
  /// Parameters:
  /// - [apiKey]: Anthropic API key
  /// - [client]: Optional HTTP client (defaults to http.Client())
  ClaudeAiService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Creates a service instance using the default API key from environment
  ///
  /// The API key is read from environment variables via [AiConfig.getApiKey()].
  ///
  /// Throws [Exception] if API key is not configured.
  factory ClaudeAiService.withDefaultKey() {
    return ClaudeAiService(apiKey: AiConfig.getApiKey());
  }

  /// Generates learning activities from source text using Claude AI
  ///
  /// This is the main method for generating activities. It:
  /// 1. Validates the source text
  /// 2. Builds a prompt based on configuration
  /// 3. Calls Claude API
  /// 4. Parses and validates the response
  /// 5. Returns structured activities and vocabulary
  ///
  /// Parameters:
  /// - [sourceText]: The text content to generate activities from (50-5000 words)
  /// - [config]: Configuration specifying activity types, counts, difficulty, etc.
  ///
  /// Returns [AiGenerationResponse] containing generated activities and metadata
  ///
  /// Throws [AiGenerationException] if:
  /// - Source text is invalid (too short/long)
  /// - API request fails
  /// - Response cannot be parsed
  /// - Network timeout occurs
  ///
  /// Example:
  /// ```dart
  /// final config = GenerationConfig(
  ///   gradeLevel: '5th',
  ///   difficulty: 'intermediate',
  ///   multipleChoiceCount: 5,
  ///   fillBlankCount: 3,
  /// );
  ///
  /// final response = await service.generateActivities(
  ///   sourceText: myLessonText,
  ///   config: config,
  /// );
  /// ```
  Future<AiGenerationResponse> generateActivities({
    required String sourceText,
    required GenerationConfig config,
  }) async {
    final startTime = DateTime.now();

    try {
      // 1. Validate source text
      final validation = PromptBuilderService.validateSourceText(sourceText);
      if (!validation.isValid) {
        throw AiGenerationException(validation.message);
      }

      // 2. Build prompt
      final prompt = PromptBuilderService.buildActivityGenerationPrompt(
        sourceText: sourceText,
        config: config,
      );

      // 3. Call Claude API
      final response = await _callClaudeApi(prompt);

      // 4. Parse activities
      final activities = _parseActivities(response);

      // 5. Validate we got enough activities
      if (activities.length < config.totalActivities * 0.5) {
        print('Warning: Only generated ${activities.length} out of '
            '${config.totalActivities} requested activities');
      }

      // 6. Parse vocabulary
      final vocabList = response['vocabulary'] as List?;
      final vocabulary = vocabList
              ?.map((v) => VocabularyItem.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [];

      // 7. Extract summary
      final summary = response['summary'] as String? ??
          'Generated ${activities.length} activities for ${config.gradeLevel} grade.';

      // 8. Calculate generation time
      final generationTime = DateTime.now().difference(startTime);

      // 9. Create metadata
      final metadata = {
        'model': AiConfig.modelName,
        'gradeLevel': config.gradeLevel,
        'difficulty': config.difficulty,
        'sourceWordCount': sourceText.split(RegExp(r'\s+')).length,
        'activitiesRequested': config.totalActivities,
        'activitiesGenerated': activities.length,
        'generationTimeMs': generationTime.inMilliseconds,
      };

      // 10. Return response
      return AiGenerationResponse(
        activities: activities,
        vocabulary: vocabulary,
        summary: summary,
        totalActivities: activities.length,
        generationTime: generationTime,
        metadata: metadata,
        sourceText: sourceText,
      );
    } on AiGenerationException {
      rethrow; // Pass through our custom exceptions
    } catch (e, stackTrace) {
      throw AiGenerationException(
        'Failed to generate activities: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Makes a request to Claude API with the given prompt
  ///
  /// Handles:
  /// - Building the request with proper headers and authentication
  /// - Setting timeout duration
  /// - Parsing the response
  /// - Extracting the text content from Claude's response format
  /// - Automatic retry with exponential backoff on transient failures
  /// - Platform detection: Uses Cloud Functions on web, direct API on mobile/desktop
  ///
  /// The method will retry up to 3 times on:
  /// - Network timeouts
  /// - Rate limiting (429 status)
  /// - Temporary server errors
  ///
  /// Parameters:
  /// - [prompt]: The prompt to send to Claude
  ///
  /// Returns the parsed JSON response from Claude
  ///
  /// Throws [AiGenerationException] if request fails or times out
  Future<Map<String, dynamic>> _callClaudeApi(String prompt) async {
    // On web, use Firebase Cloud Functions to avoid CORS issues
    if (kIsWeb) {
      return await _callClaudeViaCloudFunction(prompt);
    }

    // On mobile/desktop, call API directly
    return await _callClaudeApiDirect(prompt);
  }

  /// Calls Claude API via Firebase Cloud Function (for web platform)
  ///
  /// This method is used when running on web to avoid CORS issues.
  /// The Cloud Function acts as a proxy, calling the Anthropic API server-side.
  Future<Map<String, dynamic>> _callClaudeViaCloudFunction(String prompt) async {
    try {
      // Get Firebase Auth token for authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw AiGenerationException('You must be logged in to generate activities.');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw AiGenerationException('Failed to get authentication token.');
      }

      // Call Cloud Function via HTTP POST
      final functionUrl = 'https://us-central1-attenglish-dev.cloudfunctions.net/generateActivitiesWithAI';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'prompt': prompt,
          'apiKey': apiKey,
        }),
      ).timeout(AiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw AiGenerationException(
            'Cloud Function failed: ${data['error'] ?? 'Unknown error'}',
          );
        }
      } else if (response.statusCode == 401) {
        throw AiGenerationException('Authentication failed. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw AiGenerationException('Invalid API key. Please check your configuration.');
      } else if (response.statusCode == 429) {
        throw AiGenerationException('Rate limit exceeded. Please try again in a few minutes.');
      } else {
        throw AiGenerationException(
          'Cloud Function error: ${response.statusCode}\n${response.body}',
        );
      }
    } on TimeoutException {
      throw AiGenerationException(
        'Request timed out after ${AiConfig.requestTimeout.inSeconds} seconds. '
        'Please try again.',
      );
    } catch (e) {
      if (e is AiGenerationException) {
        rethrow;
      }
      throw AiGenerationException(
        'Failed to call Cloud Function: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Calls Claude API directly (for mobile/desktop platforms)
  ///
  /// This method makes direct HTTP calls to the Anthropic API.
  /// Only works on mobile and desktop due to CORS restrictions on web.
  Future<Map<String, dynamic>> _callClaudeApiDirect(String prompt) async {
    const maxRetries = 3;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Make API call with timeout
        final response = await _client
            .post(
              Uri.parse('${AiConfig.apiBaseUrl}/messages'),
              headers: {
                'x-api-key': apiKey,
                'anthropic-version': AiConfig.apiVersion,
                'content-type': 'application/json',
              },
              body: jsonEncode({
                'model': AiConfig.modelName,
                'max_tokens': AiConfig.maxTokensPerRequest,
                'messages': [
                  {
                    'role': 'user',
                    'content': prompt,
                  }
                ],
              }),
            )
            .timeout(AiConfig.requestTimeout);

        // Handle successful response
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final content = data['content'][0]['text'] as String;

          // Clean markdown code blocks if present (Claude sometimes wraps JSON in ```json)
          final cleanedContent = content
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();

          // Parse as JSON and return
          return jsonDecode(cleanedContent) as Map<String, dynamic>;
        }
        // Handle rate limiting
        else if (response.statusCode == 429) {
          if (attempt < maxRetries - 1) {
            // Exponential backoff: wait 2s, 4s, 6s
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
            continue; // Retry
          }
          throw AiGenerationException(
            'Rate limit exceeded. Please try again in a few minutes.',
          );
        }
        // Handle authentication errors
        else if (response.statusCode == 401) {
          throw AiGenerationException(
            'Invalid API key. Please check your configuration.',
          );
        }
        // Handle other API errors
        else {
          throw AiGenerationException(
            'API error: ${response.statusCode}\n${response.body}',
          );
        }
      } on TimeoutException {
        if (attempt < maxRetries - 1) {
          continue; // Retry on timeout
        }
        throw AiGenerationException(
          'Request timed out after ${AiConfig.requestTimeout.inSeconds} seconds. '
          'Please try again.',
        );
      } on FormatException catch (e) {
        throw AiGenerationException(
          'Invalid JSON response from API. The AI may have returned '
          'improperly formatted data.',
          originalError: e,
        );
      } catch (e, stackTrace) {
        // Retry on transient errors
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        }
        // Give up after max retries
        throw AiGenerationException(
          'Failed to call API: ${e.toString()}',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    }

    // Should never reach here, but just in case
    throw AiGenerationException('Failed after $maxRetries attempts');
  }

  /// Parses activities from Claude's JSON response
  ///
  /// Converts the raw JSON activities array into a list of [ActivityModel] objects.
  /// Handles different activity types (multiple choice, fill blank, true/false, drag & drop).
  ///
  /// This method is resilient to partial failures - if some activities fail to parse,
  /// it will continue parsing the rest and return what it can. A warning is logged
  /// for any activities that fail.
  ///
  /// Parameters:
  /// - [response]: The parsed JSON response from Claude API
  ///
  /// Returns list of [ActivityModel] objects ready to use in lessons
  ///
  /// Throws [AiGenerationException] if:
  /// - No activities array is present in response
  /// - All activities fail to parse
  List<ActivityModel> _parseActivities(Map<String, dynamic> response) {
    final activitiesList = response['activities'] as List?;

    if (activitiesList == null || activitiesList.isEmpty) {
      throw AiGenerationException(
        'No activities were generated. The AI response was empty.',
      );
    }

    final activities = <ActivityModel>[];
    final errors = <String>[];

    for (int i = 0; i < activitiesList.length; i++) {
      try {
        final activityJson = activitiesList[i] as Map<String, dynamic>;
        final activity = _convertToActivityModel(activityJson, i);
        activities.add(activity);
      } catch (e) {
        errors.add('Activity $i: ${e.toString()}');
        // Continue parsing other activities
      }
    }

    if (activities.isEmpty && errors.isNotEmpty) {
      throw AiGenerationException(
        'Failed to parse any activities:\n${errors.join('\n')}',
      );
    }

    // Log warnings if some activities failed
    if (errors.isNotEmpty) {
      print('Warning: Some activities failed to parse:\n${errors.join('\n')}');
    }

    return activities;
  }

  /// Converts a single activity JSON object to ActivityModel
  ///
  /// Handles the different fields required for each activity type:
  /// - Multiple choice: question, options, correctAnswerIndex OR correctAnswerIndices
  /// - Fill blank: question, blankSentence, correctWord
  /// - True/false: question, correctAnswer
  /// - Drag & drop: question, leftItems, rightItems, correctPairs
  ///
  /// Each activity is assigned a unique ID based on timestamp and index.
  ///
  /// Parameters:
  /// - [json]: Single activity JSON object
  /// - [index]: Index of the activity (for ordering)
  ///
  /// Returns a properly formatted [ActivityModel]
  ///
  /// Throws [AiGenerationException] if required fields are missing or invalid
  ActivityModel _convertToActivityModel(Map<String, dynamic> json, int index) {
    final type = json['type'] as String;
    final id = '${DateTime.now().millisecondsSinceEpoch}_$index';

    switch (type) {
      case 'multiple_choice':
        // Handle both single answer and multiple answers
        final correctAnswerIndex = json['correctAnswerIndex'] as int?;
        final correctAnswerIndices = json['correctAnswerIndices'] != null
            ? List<int>.from(json['correctAnswerIndices'] as List)
            : null;

        return ActivityModel(
          id: id,
          type: type,
          question: json['question'] as String,
          options: List<String>.from(json['options'] as List),
          correctAnswerIndex: correctAnswerIndex,
          correctAnswerIndices: correctAnswerIndices,
          points: json['points'] as int? ?? 10,
        );

      case 'fill_blank':
        // Handle both single correctAnswer and array of correctAnswers
        final correctAnswers = json['correctAnswers'] != null
            ? List<String>.from(json['correctAnswers'] as List)
            : [json['correctAnswer'] as String];

        return ActivityModel(
          id: id,
          type: type,
          question: json['question'] as String,
          blankSentence: json['question'] as String,
          correctWord: correctAnswers.first,
          points: json['points'] as int? ?? 10,
        );

      case 'true_false':
        return ActivityModel(
          id: id,
          type: type,
          question: json['question'] as String,
          correctAnswer: json['correctAnswer'] as bool,
          points: json['points'] as int? ?? 5,
        );

      case 'drag_drop':
        // Parse correctPairs from index mapping to string mapping
        // Expected format from AI: {"0": 0, "1": 1, "2": 2} (left index -> right index)
        // Need to convert to: {"Cat": "Meow", "Dog": "Woof"} (left item -> right item)
        final leftItems = List<String>.from(json['leftItems'] as List);
        final rightItems = List<String>.from(json['rightItems'] as List);
        final pairsJson = json['correctPairs'] as Map;

        final correctPairs = <String, String>{};
        pairsJson.forEach((key, value) {
          final leftIndex = key is int ? key : int.parse(key.toString());
          final rightIndex = value is int ? value : int.parse(value.toString());

          // Convert indices to actual string values
          if (leftIndex < leftItems.length && rightIndex < rightItems.length) {
            correctPairs[leftItems[leftIndex]] = rightItems[rightIndex];
          }
        });

        return ActivityModel(
          id: id,
          type: type,
          question: json['question'] as String,
          leftItems: leftItems,
          rightItems: rightItems,
          correctPairs: correctPairs,
          points: json['points'] as int? ?? 15,
        );

      default:
        throw AiGenerationException('Unknown activity type: $type');
    }
  }

  /// Disposes of resources used by this service
  ///
  /// Closes the HTTP client to free up resources.
  /// Call this when you're done using the service.
  ///
  /// Example:
  /// ```dart
  /// final service = ClaudeAiService.withDefaultKey();
  /// try {
  ///   await service.generateActivities(...);
  /// } finally {
  ///   service.dispose(); // Always dispose
  /// }
  /// ```
  void dispose() {
    _client.close();
  }
}

/// Exception thrown when AI generation fails
///
/// This exception wraps various failure scenarios:
/// - Invalid source text
/// - API request failures
/// - Network timeouts
/// - JSON parsing errors
/// - Missing required fields in response
///
/// Contains the error message and optionally the original error and stack trace
/// for debugging purposes.
class AiGenerationException implements Exception {
  /// Human-readable error message
  final String message;

  /// Original error that caused this exception (if any)
  final Object? originalError;

  /// Stack trace from the original error (if any)
  final StackTrace? stackTrace;

  /// Creates a new AI generation exception
  ///
  /// Parameters:
  /// - [message]: Description of what went wrong
  /// - [originalError]: Optional original error for debugging
  /// - [stackTrace]: Optional stack trace for debugging
  AiGenerationException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (originalError != null) {
      return 'AiGenerationException: $message\nCaused by: $originalError';
    }
    return 'AiGenerationException: $message';
  }
}
