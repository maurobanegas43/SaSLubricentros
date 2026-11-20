import 'dart:developer' as developer;

/// SecureLogger provides logging functionality with automatic password redaction
///
/// This logger ensures that sensitive fields like passwords are never logged,
/// preventing accidental exposure in logs, crash reports, or debugging output.
class SecureLogger {
  static const List<String> _sensitiveFields = [
    'password',
    'newPassword',
    'oldPassword',
    'passwordConfirmation',
    'confirmPassword',
    'currentPassword',
    'token', // Auth tokens should also be redacted
    'authToken',
    'accessToken',
    'refreshToken',
  ];

  /// Log an informational message
  static void info(String message, {Map<String, dynamic>? data}) {
    final redactedData = data != null ? _redactSensitiveFields(data) : null;
    final logMessage =
        redactedData != null ? '$message | data: $redactedData' : message;
    developer.log(logMessage, name: 'INFO');
  }

  /// Log a warning message
  static void warning(String message, {Map<String, dynamic>? data}) {
    final redactedData = data != null ? _redactSensitiveFields(data) : null;
    final logMessage =
        redactedData != null ? '$message | data: $redactedData' : message;
    developer.log(logMessage, name: 'WARNING');
  }

  /// Log an error message
  static void error(String message,
      {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    final redactedData = data != null ? _redactSensitiveFields(data) : null;
    final logMessage =
        redactedData != null ? '$message | data: $redactedData' : message;
    developer.log(
      logMessage,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a debug message (only in debug mode)
  static void debug(String message, {Map<String, dynamic>? data}) {
    assert(() {
      final redactedData = data != null ? _redactSensitiveFields(data) : null;
      final logMessage =
          redactedData != null ? '$message | data: $redactedData' : message;
      developer.log(logMessage, name: 'DEBUG');
      return true;
    }());
  }

  /// Redact sensitive fields from a map
  static Map<String, dynamic> _redactSensitiveFields(
      Map<String, dynamic> data) {
    final redacted = <String, dynamic>{};

    data.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      final isSensitive = _sensitiveFields
          .any((field) => lowerKey.contains(field.toLowerCase()));

      if (isSensitive) {
        redacted[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        // Recursively redact nested maps
        redacted[key] = _redactSensitiveFields(value);
      } else if (value is List) {
        // Recursively redact lists of maps
        redacted[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _redactSensitiveFields(item);
          }
          return item;
        }).toList();
      } else {
        redacted[key] = value;
      }
    });

    return redacted;
  }

  /// Check if a string contains sensitive information
  static bool containsSensitiveInfo(String text) {
    final lowerText = text.toLowerCase();
    return _sensitiveFields
        .any((field) => lowerText.contains(field.toLowerCase()));
  }
}
