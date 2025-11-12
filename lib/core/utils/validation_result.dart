/// Simple class to return validation results
///
/// Used throughout the app to return validation results with
/// a consistent pattern. Replaces throwing exceptions or returning
/// simple booleans by providing both success/failure state and
/// a descriptive message.
///
/// Example usage:
/// ```dart
/// ValidationResult validateEmail(String email) {
///   if (email.isEmpty) {
///     return ValidationResult.error('Email is required');
///   }
///   if (!email.contains('@')) {
///     return ValidationResult.error('Invalid email format');
///   }
///   return ValidationResult.success('Email is valid');
/// }
///
/// final result = validateEmail('test@example.com');
/// if (result.isError) {
///   print('Validation failed: ${result.message}');
/// } else {
///   print('Success: ${result.message}');
/// }
/// ```
class ValidationResult {
  /// Whether the validation passed
  final bool isValid;

  /// Validation message (success or error description)
  final String message;

  /// Private constructor
  ///
  /// Use factory constructors [success] or [error] instead
  const ValidationResult._(this.isValid, this.message);

  /// Creates a successful validation result
  ///
  /// Example:
  /// ```dart
  /// return ValidationResult.success('Configuration is valid');
  /// ```
  factory ValidationResult.success(String message) {
    return ValidationResult._(true, message);
  }

  /// Creates a failed validation result
  ///
  /// Example:
  /// ```dart
  /// return ValidationResult.error('API key is missing');
  /// ```
  factory ValidationResult.error(String message) {
    return ValidationResult._(false, message);
  }

  /// Whether the validation failed
  ///
  /// Convenience getter that's the inverse of [isValid]
  bool get isError => !isValid;

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, message: $message)';
  }
}
