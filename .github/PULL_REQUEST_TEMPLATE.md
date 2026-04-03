# Pull Request

## Description
<!-- Describe your changes -->

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Checklist

### General
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests pass locally

### Security (Authentication/Password Handling)
**If this PR touches authentication, passwords, or user credentials:**

- [ ] No passwords logged (checked with `grep -r "log.*password" backend/`)
- [ ] No passwords in print statements (checked with `grep -r "print.*password" mobile/`)
- [ ] Using `LoggingMiddleware` for backend logging
- [ ] Using `SecureLogger` for mobile logging
- [ ] API responses exclude password/password_hash fields
- [ ] Error messages are generic (don't reveal password info)
- [ ] Database uses password_hash (not plaintext password)
- [ ] Security tests pass (`./scripts/verify-password-security.sh`)
- [ ] Pre-commit hook passes

### Testing
- [ ] Unit tests added for new functionality
- [ ] Property-based tests added where applicable
- [ ] Integration tests updated if needed
- [ ] Test coverage maintained or improved

## Related Issues
<!-- Link to related issues -->

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Additional Notes
<!-- Any additional information for reviewers -->
