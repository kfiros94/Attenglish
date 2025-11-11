/// Configuration class for Claude AI API integration
///
/// This class manages all settings and configurations related to
/// the Anthropic Claude API, including API keys, model selection,
/// and request limits.
class AiConfig {
  // Private constructor to prevent instantiation
  AiConfig._();

  // API Configuration
  /// Base URL for Anthropic API endpoints
  static const String apiBaseUrl = 'https://api.anthropic.com/v1';

  /// Claude model identifier to use for content generation
  /// Using Claude Sonnet 4 (latest stable version)
  static const String modelName = 'claude-sonnet-4-20250514';

  /// API version header required by Anthropic
  static const String apiVersion = '2023-06-01';

  // Request Limits
  /// Maximum number of tokens allowed per API request
  /// This controls the length of generated content
  static const int maxTokensPerRequest = 4096;

  /// Timeout duration for API requests
  /// Requests exceeding this duration will be cancelled
  static const Duration requestTimeout = Duration(seconds: 60);

  /// Maximum number of words accepted in a single request
  /// Used for validation before sending to API
  static const int maxWordsPerRequest = 5000;

  /// Minimum number of words required for content generation
  /// Prevents generating content from too little context
  static const int minWordsPerRequest = 50;

  // Usage Limits
  /// Number of free AI generations allowed per month per user
  /// Used for quota management
  static const int freeGenerationsPerMonth = 50;

  /// Retrieves the Anthropic API key from environment variables
  ///
  /// The API key must be provided via --dart-define during app launch:
  /// ```
  /// flutter run --dart-define=ANTHROPIC_API_KEY=your_key_here
  /// ```
  ///
  /// Returns the configured API key
  ///
  /// Throws [Exception] if the API key is not configured
  static String getApiKey() {
    const apiKey = String.fromEnvironment(
      'ANTHROPIC_API_KEY',
      defaultValue: '',
    );

    if (apiKey.isEmpty) {
      throw Exception(
        'Anthropic API key not configured. '
        'Run with: flutter run --dart-define=ANTHROPIC_API_KEY=your_key',
      );
    }

    return apiKey;
  }

  /// Checks if the AI configuration is properly set up
  ///
  /// Returns `true` if the API key is configured and accessible,
  /// `false` otherwise
  ///
  /// This is a safe check that doesn't throw exceptions
  static bool get isConfigured {
    try {
      getApiKey();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates the AI configuration
  ///
  /// Performs comprehensive validation of the API configuration:
  /// - Checks if API key exists
  /// - Validates API key format (must start with 'sk-ant-')
  /// - Prints confirmation message (without exposing the actual key)
  ///
  /// Throws [Exception] if any validation check fails
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   AiConfig.validateConfiguration();
  ///   print('AI configuration is valid');
  /// } catch (e) {
  ///   print('Configuration error: $e');
  /// }
  /// ```
  static void validateConfiguration() {
    // Check if API key exists
    final apiKey = getApiKey(); // Will throw if not configured

    // Validate API key format
    if (!apiKey.startsWith('sk-ant-')) {
      throw Exception(
        'Invalid Anthropic API key format. '
        'API key must start with "sk-ant-"',
      );
    }

    // Validate API key length (Anthropic keys are typically ~100+ characters)
    if (apiKey.length < 50) {
      throw Exception(
        'Invalid Anthropic API key. '
        'Key appears too short to be valid.',
      );
    }

    // Print confirmation (safely, without exposing the key)
    print('✅ AI Configuration validated successfully');
    print('   API Base URL: $apiBaseUrl');
    print('   Model: $modelName');
    print('   API Version: $apiVersion');
    print('   Max Tokens: $maxTokensPerRequest');
    print('   Request Timeout: ${requestTimeout.inSeconds}s');
    print('   API Key: ${apiKey.substring(0, 10)}...[REDACTED]');
  }

  /// Gets the full endpoint URL for a specific API path
  ///
  /// Example:
  /// ```dart
  /// final messagesUrl = AiConfig.getEndpoint('/messages');
  /// // Returns: 'https://api.anthropic.com/v1/messages'
  /// ```
  static String getEndpoint(String path) {
    return '$apiBaseUrl$path';
  }

  /// Gets the headers required for API requests
  ///
  /// Returns a map of HTTP headers including:
  /// - API key authentication
  /// - API version
  /// - Content type
  ///
  /// Example:
  /// ```dart
  /// final headers = AiConfig.getHeaders();
  /// final response = await http.post(url, headers: headers, body: body);
  /// ```
  static Map<String, String> getHeaders() {
    return {
      'x-api-key': getApiKey(),
      'anthropic-version': apiVersion,
      'content-type': 'application/json',
    };
  }
}
