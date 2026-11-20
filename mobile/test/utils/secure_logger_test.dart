import 'package:flutter_test/flutter_test.dart';
import 'package:lubricentros_app/utils/secure_logger.dart';

void main() {
  group('SecureLogger', () {
    test('redacts password field', () {
      final data = {
        'email': 'test@example.com',
        'password': 'SecretPass123',
      };

      // The logger should redact the password
      // We can't directly test log output, but we can test the redaction logic
      final containsSensitive = SecureLogger.containsSensitiveInfo('password');
      expect(containsSensitive, isTrue);
    });

    test('redacts newPassword field', () {
      final containsSensitive = SecureLogger.containsSensitiveInfo('newPassword');
      expect(containsSensitive, isTrue);
    });

    test('redacts token fields', () {
      final containsSensitive = SecureLogger.containsSensitiveInfo('authToken');
      expect(containsSensitive, isTrue);
    });

    test('does not flag non-sensitive fields', () {
      final containsSensitive = SecureLogger.containsSensitiveInfo('email');
      expect(containsSensitive, isFalse);
    });

    test('detects sensitive info in mixed case', () {
      final containsSensitive = SecureLogger.containsSensitiveInfo('Password');
      expect(containsSensitive, isTrue);
    });

    test('detects sensitive info in compound words', () {
      final containsSensitive = SecureLogger.containsSensitiveInfo('userPassword');
      expect(containsSensitive, isTrue);
    });
  });
}
