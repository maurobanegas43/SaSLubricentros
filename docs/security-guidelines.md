# Security Guidelines - Password Handling

## Overview

This document provides security guidelines for handling passwords and sensitive data in the Lubricentros authentication system. Following these guidelines is **mandatory** for all code contributions.

## Critical Rules

### 🚫 NEVER Log Passwords

Passwords must NEVER appear in:
- Application logs
- Debug output
- Error messages
- Console output
- Crash reports
- Audit logs

### ✅ Always Use Password Hashes

- Store only bcrypt hashes in the database (password_hash column)
- Hash passwords immediately upon receipt
- Never store plaintext passwords, even temporarily
- Use bcrypt cost factor of 12

### 🔒 Protect Password in Transit

- Always use HTTPS/TLS for API communication
- Never send passwords in URL parameters or query strings
- Only send passwords in request body over POST requests

## Backend (Go) Guidelines

### DO: Proper Password Handling

```go
// ✅ Good: Hash password immediately, don't log it
func (s *AuthService) RegisterUser(req RegisterRequest) (*AuthResponse, error) {
    // Hash password immediately
    passwordHash, err := bcrypt.GenerateFromPassword([]byte(req.Password), s.bcryptCost)
    if err != nil {
        log.Printf("Failed to hash password for email=%s", req.Email) // ✅ No password in log
        return nil, err
    }

    // Clear password from memory (optional but recommended)
    req.Password = ""

    // Store only the hash
    user := &User{
        Email:        req.Email,
        PasswordHash: string(passwordHash),
        Name:         req.Name,
    }

    // Log success without password
    log.Printf("User registered successfully: email=%s", user.Email) // ✅ No password
    
    return response, nil
}
```

```go
// ✅ Good: Use logging middleware that redacts passwords
middleware := NewLoggingMiddleware(logger)
router.Use(middleware.Middleware)
```

```go
// ✅ Good: Explicit field logging
log.Printf("Login attempt: email=%s ip=%s", email, ipAddress)
```

### DON'T: Password Anti-patterns

```go
// ❌ Bad: Logging password directly
log.Printf("User login: email=%s password=%s", email, password)

// ❌ Bad: Logging entire request object (may contain password)
log.Printf("Request: %+v", req)

// ❌ Bad: Logging JSON that includes password
reqJSON, _ := json.Marshal(req)
log.Printf("Request body: %s", reqJSON)

// ❌ Bad: Including password in error messages
return fmt.Errorf("failed to authenticate user %s with password %s", email, password)

// ❌ Bad: Returning password in response
type UserResponse struct {
    Email        string `json:"email"`
    PasswordHash string `json:"password_hash"` // ❌ Never expose hash
}
```

### Response Structures

Always use dedicated response structs that exclude password fields:

```go
// ✅ Good: Response struct without password
type UserData struct {
    ID    int    `json:"id"`
    Email string `json:"email"`
    Name  string `json:"name"`
    Phone string `json:"phone,omitempty"`
    // No password or password_hash fields
}

// ✅ Good: Convert database model to response model
func (u *User) ToUserData() UserData {
    return UserData{
        ID:    u.ID,
        Email: u.Email,
        Name:  u.Name,
        Phone: u.Phone,
    }
}
```

### Error Handling

```go
// ✅ Good: Generic error messages
if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
    log.Printf("Failed login attempt: email=%s ip=%s", req.Email, ipAddress) // ✅ No password
    return nil, errors.New("invalid email or password")
}

// ❌ Bad: Specific error that reveals information
if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
    return nil, fmt.Errorf("password %s does not match hash", req.Password) // ❌ Exposes password
}
```

## Mobile (Flutter/Dart) Guidelines

### DO: Proper Password Handling

```dart
// ✅ Good: Use SecureLogger that redacts passwords
import 'package:lubricentros_app/utils/secure_logger.dart';

Future<void> login(String email, String password) async {
  try {
    SecureLogger.info('Login attempt', data: {
      'email': email,
      // Don't include password in log data
    });
    
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    SecureLogger.info('Login successful', data: {'email': email});
  } catch (e) {
    SecureLogger.error('Login failed', error: e, data: {
      'email': email,
      // Don't include password in error log
    });
  }
}
```

```dart
// ✅ Good: Clear password from controller after use
void _handleSubmit() async {
  final password = _passwordController.text;
  
  try {
    await authService.login(email: _emailController.text, password: password);
    
    // Clear password from memory
    _passwordController.clear();
  } catch (e) {
    // Handle error without logging password
    SecureLogger.error('Login failed', error: e);
  }
}
```

```dart
// ✅ Good: Dispose controllers properly
@override
void dispose() {
  _passwordController.dispose();
  _emailController.dispose();
  super.dispose();
}
```

### DON'T: Password Anti-patterns

```dart
// ❌ Bad: Using print() with password
print('Login with password: $password');

// ❌ Bad: Using debugPrint() with password
debugPrint('Password entered: $password');

// ❌ Bad: Logging entire request object
final request = {'email': email, 'password': password};
print('Request: $request'); // ❌ Exposes password

// ❌ Bad: Including password in error messages
throw Exception('Failed to login with password: $password');

// ❌ Bad: Storing password in state
class LoginState {
  final String email;
  final String password; // ❌ Don't store password in state
}
```

### Network Logging

```dart
// ✅ Good: Redact password from network logs
class ApiClient {
  Future<Response> post(String path, Map<String, dynamic> body) async {
    final redactedBody = Map<String, dynamic>.from(body);
    if (redactedBody.containsKey('password')) {
      redactedBody['password'] = '[REDACTED]';
    }
    
    SecureLogger.debug('API request', data: {
      'path': path,
      'body': redactedBody, // ✅ Password redacted
    });
    
    return await _client.post(path, body: body);
  }
}
```

## Database Guidelines

### Schema Design

```sql
-- ✅ Good: Store only password hash
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,  -- ✅ Hash, not plaintext
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ❌ Bad: Storing plaintext password
CREATE TABLE users (
    password VARCHAR(255) NOT NULL,  -- ❌ Never store plaintext
);
```

### Query Logging

```go
// ✅ Good: Use parameterized queries (prevents SQL injection and logging)
stmt, err := db.Prepare("INSERT INTO users (email, password_hash, name) VALUES ($1, $2, $3)")
result, err := stmt.Exec(user.Email, user.PasswordHash, user.Name)

// ❌ Bad: String concatenation (security risk and may log password)
query := fmt.Sprintf("INSERT INTO users (email, password_hash) VALUES ('%s', '%s')", 
    email, passwordHash) // ❌ Avoid string formatting for queries
```

## Testing Guidelines

### Unit Tests

```go
// ✅ Good: Test password redaction
func TestPasswordRedaction(t *testing.T) {
    body := `{"email":"test@example.com","password":"Secret123"}`
    
    // Process through logging middleware
    // ...
    
    // Verify password is not in log output
    if strings.Contains(logOutput, "Secret123") {
        t.Error("Password found in logs - security violation!")
    }
}
```

### Integration Tests

```dart
// ✅ Good: Verify password not in network logs
test('password not logged during login', () async {
  final logCapture = LogCapture();
  
  await authService.login(
    email: 'test@example.com',
    password: 'TestPassword123',
  );
  
  // Verify password is not in any log output
  expect(logCapture.logs, isNot(contains('TestPassword123')));
  expect(logCapture.logs, contains('[REDACTED]'));
});
```

## Code Review Checklist

When reviewing authentication-related code, verify:

- [ ] No `log.*password` or `logger.*password` statements
- [ ] No `print(.*password)` or `debugPrint(.*password)` statements
- [ ] No `fmt.Printf.*password` statements
- [ ] Request logging uses redaction middleware
- [ ] API response structs don't include password fields
- [ ] Error messages are generic and don't expose passwords
- [ ] Database queries use parameterized statements
- [ ] Password variables are cleared after use
- [ ] Audit logs only record events, not password values
- [ ] Test files don't accidentally log real passwords

## Automated Checks

### Pre-commit Hook

Install the pre-commit hook to catch password logging before commit:

```bash
./setup-git-hooks.sh
```

This hook will:
- Scan Go files for password logging patterns
- Scan Dart files for password logging patterns
- Check for hardcoded secrets
- Prevent commits that violate security rules

### Linting

Run linters to detect password logging:

```bash
# Go
golangci-lint run

# Dart
flutter analyze
```

### CI/CD Pipeline

The CI pipeline includes:
- Static analysis for password logging
- Security tests that verify password redaction
- Code coverage for security-critical paths

## Incident Response

If a password is accidentally logged or exposed:

1. **Immediate**: Remove the log statement and deploy fix
2. **Rotate**: Force password reset for affected users
3. **Audit**: Review all logs to identify exposure scope
4. **Notify**: Inform affected users if exposure is confirmed
5. **Review**: Conduct post-mortem to prevent recurrence

## References

- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- Design Document: `.kiro/specs/authentication/design.md`
- Security Audit: `.kiro/specs/authentication/security-audit-passwords.md`

## Summary

**Key Takeaways**:
1. Never log passwords - use [REDACTED] or omit entirely
2. Store only bcrypt hashes in database
3. Exclude password fields from API responses
4. Use generic error messages
5. Clear passwords from memory after use
6. Use automated checks (hooks, linters, tests)

Following these guidelines ensures the authentication system maintains the highest security standards for password protection.
