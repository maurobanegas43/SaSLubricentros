# Password Security Checklist

Quick reference for developers implementing authentication features.

## ❌ NEVER DO

```go
// ❌ Go: Never log passwords
log.Printf("User password: %s", password)
logger.Info("Login", "password", password)
fmt.Printf("Password: %s", password)
```

```dart
// ❌ Dart: Never log passwords
print('Password: $password');
debugPrint('User password: $password');
developer.log('password: $password');
```

```go
// ❌ Never return passwords in API responses
type UserResponse struct {
    Password     string `json:"password"`      // ❌ Never
    PasswordHash string `json:"password_hash"` // ❌ Never
}
```

```sql
-- ❌ Never store plaintext passwords
CREATE TABLE users (
    password VARCHAR(255) -- ❌ Never
);
```

## ✅ ALWAYS DO

```go
// ✅ Go: Use logging middleware with redaction
middleware := middleware.NewLoggingMiddleware(logger)
router.Use(middleware.Middleware)

// ✅ Log events without passwords
log.Printf("Login attempt: email=%s ip=%s", email, ipAddress)
```

```dart
// ✅ Dart: Use SecureLogger
import 'package:lubricentros_app/utils/secure_logger.dart';

SecureLogger.info('Login attempt', data: {'email': email});
```

```go
// ✅ Store only bcrypt hashes
passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), 12)
user.PasswordHash = string(passwordHash)
```

```go
// ✅ Exclude passwords from responses
type UserData struct {
    ID    int    `json:"id"`
    Email string `json:"email"`
    Name  string `json:"name"`
    // No password fields
}
```

```sql
-- ✅ Store only password hash
CREATE TABLE users (
    password_hash VARCHAR(255) NOT NULL
);
```

## Quick Setup

```bash
# Install git hooks
./setup-git-hooks.sh

# Run security tests
cd backend && go test ./internal/middleware/... -v
cd mobile && flutter test test/utils/secure_logger_test.dart

# Run linters
cd backend && golangci-lint run
cd mobile && flutter analyze
```

## Before Committing

- [ ] No `log.*password` in Go files
- [ ] No `print.*password` in Dart files
- [ ] API responses exclude password fields
- [ ] Using LoggingMiddleware (Go) or SecureLogger (Dart)
- [ ] Security tests pass
- [ ] Pre-commit hook passes

## Resources

- Full guidelines: `docs/security-guidelines.md`
- Security audit: `.kiro/specs/authentication/security-audit-passwords.md`
- Implementation details: `.kiro/specs/authentication/SECURITY-IMPLEMENTATION.md`
