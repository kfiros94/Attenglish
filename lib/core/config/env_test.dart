/// Test file to verify environment variable configuration
/// Call this from main.dart temporarily to verify the API key is configured
void testApiKey() {
  const apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  print('=== API Key Configuration Test ===');
  print('API Key configured: ${apiKey.isNotEmpty}');
  print('API Key length: ${apiKey.length}');

  if (apiKey.isEmpty) {
    print('⚠️  WARNING: API key is not configured!');
    print('Make sure to run with: flutter run --dart-define=ANTHROPIC_API_KEY=your_key');
    print('Or use the VS Code launch configuration.');
  } else {
    print('✅ API Key is configured');
    print('First 7 characters: ${apiKey.substring(0, apiKey.length > 7 ? 7 : apiKey.length)}...');
  }

  print('==================================');

  // Don't print the actual key for security!
}

/// Get the API key at runtime
String getAnthropicApiKey() {
  const apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  if (apiKey.isEmpty) {
    throw Exception(
      'ANTHROPIC_API_KEY not configured. '
      'Please run with --dart-define=ANTHROPIC_API_KEY=your_key',
    );
  }

  return apiKey;
}
