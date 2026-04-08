# Implementation Plan: Authentication Feature

## Overview

This implementation plan builds a secure, mobile-first authentication system for the Lubricentros app.
Tasks are organized by layer: Mobile UX/IA → Backend API → Database → Testing.

Priority focus: User experience, security best practices, and resource efficiency.

## Tasks

### Phase 1: Mobile Foundation & Core UI Components

- [ ] 1. Set up mobile authentication infrastructure
  - Add dependencies: flutter_secure_storage, provider, email_validator to pubspec.yaml
  - Create directory structure: lib/features/auth/{models,services,screens,widgets,validators}
  - Set up navigation routes for authentication flows
  - _Requirements: 8.1, 8.6, 8.7, 8.8_


- [ ] 2. Implement input validation system
  - [ ] 2.1 Create InputValidator class with validation methods
    - Implement RFC 5322 email format validation
    - Implement password strength validation (≥8 chars, uppercase, lowercase, number)
    - Implement password confirmation matching and name length validation (≥2 chars)
    - _Requirements: 1.2, 1.3, 1.4, 2.2, 3.2, 6.1, 6.2, 6.3, 6.4_
  
  - [ ]* 2.2 Write property tests for InputValidator
    - **Property 1: Email Format Validation**
    - **Property 2: Password Strength Validation**
    - **Property 3: Password Confirmation Matching**
    - **Property 4: Name Length Validation**
    - **Validates: Requirements 1.2, 1.3, 1.4, 6.1-6.4**

- [ ] 3. Create secure storage service
  - [ ] 3.1 Implement SecureStorageService using flutter_secure_storage
    - Create methods: saveToken, getToken, deleteToken, saveUserData, getUserData, clearAll
    - Configure iOS Keychain (kSecAttrAccessibleAfterFirstUnlock)
    - Configure Android EncryptedSharedPreferences (AES-256)
    - _Requirements: 1.10, 2.9, 4.1, 4.8_
  
  - [ ]* 3.2 Write unit tests for SecureStorageService
    - Test token storage and retrieval
    - Test data persistence across app restarts
    - Test clearAll functionality
    - _Requirements: 4.1, 4.8_

- [ ] 4. Build authentication data models
  - Create AuthResult, AuthState, UserData, ValidationResult models
  - Create PasswordStrength enum
  - Add JSON serialization/deserialization
  - _Requirements: 1.9, 2.7_


### Phase 2: Mobile UI Screens & User Flows

- [ ] 5. Implement Registration Screen UI
  - [ ] 5.1 Create RegistrationScreen with form fields
    - Build email, password, password confirmation, name, phone (optional) input fields
    - Add real-time validation feedback with error messages below fields
    - Implement password strength indicator widget
    - Add loading state with spinner and disabled inputs
    - Add navigation link to login screen
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.12, 7.1, 7.6, 7.7, 7.8, 7.9_
  
  - [ ]* 5.2 Write widget tests for RegistrationScreen
    - Test form validation states
    - Test navigation flows
    - Test loading and error states
    - _Requirements: 1.1, 7.1, 7.6_

- [ ] 6. Implement Login Screen UI
  - [ ] 6.1 Create LoginScreen with form fields
    - Build email and password input fields with validation
    - Add loading state during authentication
    - Add error display below submit button
    - Add navigation links to registration and password recovery screens
    - Implement consistent styling with RegistrationScreen
    - _Requirements: 2.1, 2.2, 2.3, 2.11, 2.12, 7.1, 7.3, 8.6, 8.7, 8.8_
  
  - [ ]* 6.2 Write widget tests for LoginScreen
    - Test form validation and submission
    - Test navigation to registration and password recovery
    - Test error display
    - _Requirements: 2.1, 7.3_

- [ ] 7. Implement Password Recovery Screen UI
  - [ ] 7.1 Create PasswordRecoveryScreen with email input
    - Build email input field with validation
    - Add loading state during request
    - Display success message with instructions to check email
    - Add back button to return to login
    - _Requirements: 3.1, 3.2, 3.3, 3.9, 8.1_
  
  - [ ]* 7.2 Write widget tests for PasswordRecoveryScreen
    - Test email validation
    - Test success message display
    - Test back navigation
    - _Requirements: 3.1, 3.9_


- [ ] 8. Implement Password Reset Screen UI
  - [ ] 8.1 Create PasswordResetScreen with password fields
    - Build new password and confirmation input fields
    - Add password strength indicator
    - Add loading state during reset
    - Display success message and navigate to login on success
    - Display error for invalid/expired tokens with option to resend
    - _Requirements: 3.10, 3.11, 3.15, 3.16_
  
  - [ ]* 8.2 Write widget tests for PasswordResetScreen
    - Test password validation
    - Test success and error flows
    - Test navigation after success
    - _Requirements: 3.15, 3.16_

- [ ] 9. Create reusable UI components
  - Build AuthTextField widget with validation display
  - Build AuthButton widget with loading state
  - Build PasswordStrengthIndicator widget
  - Build ErrorMessage widget with consistent styling
  - Build LoadingOverlay widget
  - _Requirements: 7.1, 7.6, 7.10, 8.6, 8.7, 8.8_

- [ ] 10. Checkpoint - UI screens complete
  - Verify all screens render correctly
  - Test navigation flows between screens
  - Ensure consistent styling across all screens
  - Ask user if questions arise

### Phase 3: Mobile Authentication Service & State Management

- [ ] 11. Implement AuthenticationService
  - [ ] 11.1 Create AuthenticationService with API communication
    - Implement register method with HTTPS POST to /api/auth/register
    - Implement login method with HTTPS POST to /api/auth/login
    - Implement requestPasswordRecovery method with POST to /api/auth/password-recovery
    - Implement resetPassword method with POST to /api/auth/password-reset
    - Implement logout method
    - Configure HTTP client with connection pooling, 30s timeout, gzip compression
    - _Requirements: 1.5, 1.6, 1.7, 2.3, 2.4, 3.3, 3.4, 3.12_
  
  - [ ]* 11.2 Write unit tests for AuthenticationService
    - Test successful registration and login flows
    - Test error handling for network failures
    - Test timeout handling
    - Test API response parsing
    - _Requirements: 1.7, 2.4, 7.4, 7.5_


- [ ] 12. Implement SessionManager
  - [ ] 12.1 Create SessionManager for session lifecycle
    - Implement initializeSession to check stored token on app start
    - Implement validateSession to verify token expiration locally
    - Implement terminateSession to clear token and navigate to login
    - Implement isTokenExpired and getTokenRemainingTime methods
    - Cache session state in memory to avoid repeated storage reads
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.8, 4.9, 4.11_
  
  - [ ]* 12.2 Write property tests for SessionManager
    - **Property 16: Session Token Persistence**
    - **Property 17: Token Expiration Validation**
    - **Property 19: Session Cleanup on Logout**
    - **Validates: Requirements 4.1-4.5, 4.8, 4.9**

- [ ] 13. Implement authentication state management
  - [ ] 13.1 Create AuthProvider using provider package
    - Implement authStateStream to broadcast authentication state changes
    - Implement methods to trigger registration, login, logout
    - Handle token storage after successful authentication
    - Handle navigation after authentication state changes
    - _Requirements: 1.10, 2.9, 4.1, 8.5_
  
  - [ ]* 13.2 Write integration tests for AuthProvider
    - Test complete registration flow with state changes
    - Test complete login flow with state changes
    - Test logout flow
    - _Requirements: 1.10, 2.9, 8.5_

- [ ] 14. Implement error handling system
  - [ ] 14.1 Create ErrorHandler for displaying errors
    - Implement methods for validation, network, authentication, and session errors
    - Display inline errors below relevant fields
    - Display banner errors at top of screen for network issues
    - Display modal dialogs for session expiration
    - Implement offline detection and display offline indicator
    - _Requirements: 1.11, 2.10, 7.3, 7.4, 7.5, 9.1, 9.2_
  
  - [ ]* 14.2 Write unit tests for ErrorHandler
    - Test error message formatting
    - Test offline detection
    - Test error display logic
    - _Requirements: 7.3, 7.4, 9.1, 9.2_


- [ ] 15. Wire mobile UI screens with services
  - [ ] 15.1 Connect RegistrationScreen to AuthProvider
    - Bind form submission to AuthProvider.register
    - Display loading state during registration
    - Handle success: store token and navigate to home
    - Handle errors: display error message and maintain form data
    - _Requirements: 1.5, 1.10, 1.11_
  
  - [ ] 15.2 Connect LoginScreen to AuthProvider
    - Bind form submission to AuthProvider.login
    - Display loading state during login
    - Handle success: store token and navigate to home
    - Handle errors: display generic error message
    - _Requirements: 2.3, 2.9, 2.10_
  
  - [ ] 15.3 Connect PasswordRecoveryScreen to AuthenticationService
    - Bind form submission to requestPasswordRecovery
    - Display loading state during request
    - Display success message regardless of email existence
    - _Requirements: 3.3, 3.9_
  
  - [ ] 15.4 Connect PasswordResetScreen to AuthenticationService
    - Bind form submission to resetPassword
    - Display loading state during reset
    - Handle success: navigate to login with success message
    - Handle errors: display error and offer to resend recovery email
    - _Requirements: 3.15, 3.16_

- [ ] 16. Implement navigation and access control
  - [ ] 16.1 Create AuthGuard for protected routes
    - Check authentication state before allowing navigation to protected screens
    - Redirect to login screen if not authenticated
    - Clear navigation stack after successful authentication
    - _Requirements: 8.2, 8.3, 8.4, 8.5_
  
  - [ ]* 16.2 Write integration tests for navigation flows
    - Test unauthenticated access prevention
    - Test navigation stack cleanup after login
    - Test back button behavior
    - _Requirements: 8.2, 8.3, 8.5_

- [ ] 17. Checkpoint - Mobile UI complete
  - Run all mobile tests
  - Verify all screens are functional with proper validation
  - Test navigation flows end-to-end
  - Ensure all tests pass, ask the user if questions arise


### Phase 4: Backend API Foundation & Security

- [ ] 18. Set up backend authentication infrastructure
  - Create directory structure: internal/auth/{handlers,services,repositories,middleware,models}
  - Add dependencies: golang-jwt/jwt, bcrypt (crypto/bcrypt), validator (go-playground/validator)
  - Create configuration for JWT secret, bcrypt cost, token expiry
  - _Requirements: 1.6, 2.6, 4.10_

- [ ] 19. Implement data models and validation
  - [ ] 19.1 Create request/response models
    - Create RegisterRequest, LoginRequest, PasswordRecoveryRequest, PasswordResetRequest structs
    - Create AuthResponse, UserData structs
    - Add JSON tags and validation tags
    - _Requirements: 1.7, 1.9, 2.7_
  
  - [ ] 19.2 Create domain models
    - Create User, PasswordResetToken, AuthAuditLog structs
    - Add database mapping tags
    - _Requirements: 10.1, 10.2, 10.3_

- [ ] 20. Implement input sanitization middleware
  - [ ] 20.1 Create InputSanitizerMiddleware
    - Implement HTML entity encoding
    - Implement SQL injection pattern detection
    - Implement whitespace trimming and Unicode normalization
    - Apply to all authentication endpoints
    - _Requirements: 6.7_
  
  - [ ]* 20.2 Write property test for input sanitization
    - **Property 22: SQL Injection Prevention**
    - **Validates: Requirements 6.7**

- [ ] 21. Implement rate limiting middleware
  - [ ] 21.1 Create RateLimiterMiddleware
    - Implement token bucket algorithm with 5 requests per minute per IP
    - Apply to all authentication endpoints
    - Return 429 Too Many Requests when limit exceeded
    - Implement cleanup of stale entries every 10 minutes
    - _Requirements: 6.8, 6.9_
  
  - [ ]* 21.2 Write property test for rate limiting
    - **Property 23: Rate Limiting Enforcement**
    - **Validates: Requirements 6.8, 6.9**


- [ ] 22. Implement authentication middleware
  - [ ] 22.1 Create AuthMiddleware for protected endpoints
    - Extract JWT from Authorization header (Bearer scheme)
    - Validate JWT signature and expiration
    - Extract user ID from claims and add to request context
    - Return 401 for invalid/missing/expired tokens
    - Implement JWT validation caching (LRU, max 1000 entries, 5-minute TTL)
    - _Requirements: 4.6, 4.7, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_
  
  - [ ]* 22.2 Write property tests for AuthMiddleware
    - **Property 18: JWT Signature Validation**
    - **Property 20: Protected Endpoint Access Control**
    - **Validates: Requirements 4.6, 4.7, 5.1-5.7**

- [ ] 23. Checkpoint - Backend security layers complete
  - Verify all middleware components are functional
  - Test rate limiting behavior
  - Test input sanitization
  - Ensure all tests pass, ask the user if questions arise

### Phase 5: Backend Authentication Service & Business Logic

- [ ] 24. Implement AuthService core logic
  - [ ] 24.1 Create AuthService with password hashing
    - Implement password hashing using bcrypt with cost factor 12
    - Implement password verification using bcrypt.CompareHashAndPassword
    - Run bcrypt operations in goroutines to avoid blocking
    - _Requirements: 1.6, 2.5_
  
  - [ ]* 24.2 Write property test for password hashing
    - **Property 5: Bcrypt Password Hashing**
    - **Validates: Requirements 1.6, 3.13**

- [ ] 25. Implement JWT token management
  - [ ] 25.1 Create JWT generation and validation methods
    - Implement GenerateJWT with user ID, email, iat, exp claims
    - Use HS256 (HMAC-SHA256) algorithm
    - Set expiration to 24 hours from issuance
    - Implement ValidateToken to verify signature and expiration
    - _Requirements: 2.6, 4.6, 4.10_
  
  - [ ]* 25.2 Write property test for JWT tokens
    - **Property 11: JWT Token Structure**
    - **Validates: Requirements 2.6, 4.10**


- [ ] 26. Implement user registration logic
  - [ ] 26.1 Create RegisterUser method in AuthService
    - Validate input using go-playground/validator
    - Check email uniqueness via UserRepository
    - Hash password using bcrypt
    - Create user record in database
    - Generate JWT token
    - Return AuthResponse with token and user data
    - Return 409 Conflict for duplicate email
    - Return 400 Bad Request for validation errors
    - _Requirements: 1.6, 1.7, 1.8, 1.9, 6.5, 6.6_
  
  - [ ]* 26.2 Write property tests for user registration
    - **Property 6: Unique Email Registration**
    - **Property 7: Successful Registration Response**
    - **Property 21: Input Validation Before Processing**
    - **Validates: Requirements 1.6-1.9, 6.5, 6.6**

- [ ] 27. Implement user login logic
  - [ ] 27.1 Create AuthenticateUser method in AuthService
    - Validate input using go-playground/validator
    - Query user by email via UserRepository
    - Verify password using bcrypt.CompareHashAndPassword
    - Generate JWT token if credentials valid
    - Return AuthResponse with token and user data
    - Return 401 Unauthorized with generic message for invalid credentials
    - _Requirements: 2.4, 2.5, 2.6, 2.7, 2.8, 2.10_
  
  - [ ]* 27.2 Write property tests for user login
    - **Property 9: Login Credential Verification**
    - **Property 10: Login Error Message Opacity**
    - **Validates: Requirements 2.4, 2.5, 2.7, 2.8, 2.10**

- [ ] 28. Implement password recovery logic
  - [ ] 28.1 Create GeneratePasswordResetToken method
    - Validate email format
    - Check if email exists in database (via UserRepository)
    - Generate cryptographically secure random token (32 bytes, hex-encoded)
    - Store token in database with 1-hour expiration
    - Send recovery email with reset link (log email for now, implement sending later)
    - Return 200 OK regardless of email existence (prevent enumeration)
    - _Requirements: 3.4, 3.5, 3.6, 3.7, 3.8_
  
  - [ ]* 28.2 Write property tests for password recovery
    - **Property 12: Password Recovery Token Generation**
    - **Property 13: Password Recovery Email Timing Attack Prevention**
    - **Validates: Requirements 3.4-3.8**


- [ ] 29. Implement password reset logic
  - [ ] 29.1 Create ResetPassword method in AuthService
    - Validate new password strength
    - Verify token exists and is not expired via TokenRepository
    - Hash new password using bcrypt
    - Update user password in database
    - Delete used token from database
    - Return 200 OK on success
    - Return 400 Bad Request for invalid/expired token
    - _Requirements: 3.12, 3.13, 3.14, 10.5_
  
  - [ ]* 29.2 Write property tests for password reset
    - **Property 14: Password Reset Token Validation**
    - **Property 15: Password Reset Token Invalidation**
    - **Validates: Requirements 3.12, 3.13, 3.14, 10.5**

- [ ] 30. Checkpoint - Backend business logic complete
  - Run all backend service tests
  - Verify all authentication flows work correctly
  - Test error handling for edge cases
  - Ensure all tests pass, ask the user if questions arise

### Phase 6: Backend API Handlers & Repository Layer

- [ ] 31. Implement repository layer
  - [ ] 31.1 Create UserRepository interface and PostgreSQL implementation
    - Implement Create, FindByEmail, FindByID, UpdatePassword, EmailExists methods
    - Use prepared statements for all queries
    - Configure connection pooling (max 25 connections, max 5 idle, 5-minute max lifetime)
    - Set query timeout to 5 seconds
    - _Requirements: 1.7, 1.8, 2.4, 3.13, 10.1_
  
  - [ ]* 31.2 Write unit tests for UserRepository
    - Test CRUD operations
    - Test email uniqueness constraint
    - Test connection pooling behavior
    - _Requirements: 1.8, 2.4, 10.1_

- [ ] 32. Implement token repository
  - [ ] 32.1 Create TokenRepository interface and PostgreSQL implementation
    - Implement CreatePasswordResetToken, FindPasswordResetToken, DeletePasswordResetToken methods
    - Implement DeleteExpiredTokens for scheduled cleanup
    - Use prepared statements and connection pooling
    - _Requirements: 3.5, 3.6, 3.12, 3.14, 10.2, 10.5, 10.6_
  
  - [ ]* 32.2 Write unit tests for TokenRepository
    - Test token creation and retrieval
    - Test token deletion
    - Test expired token cleanup
    - _Requirements: 3.14, 10.5, 10.6_


- [ ] 33. Implement audit logging
  - [ ] 33.1 Create AuditLogger for security events
    - Implement LogAuthEvent method to record authentication events
    - Log event type, email, IP address, success status, error message, timestamp
    - Create audit log entries for: registration, login, password recovery, password reset, token validation failures, rate limit violations
    - _Requirements: 6.10, 10.3_
  
  - [ ]* 33.2 Write property test for audit logging
    - **Property 24: Authentication Audit Logging**
    - **Validates: Requirements 6.10**

- [ ] 34. Implement authentication handlers
  - [ ] 34.1 Create AuthHandler with HTTP endpoint handlers
    - Implement Register handler for POST /api/auth/register
    - Implement Login handler for POST /api/auth/login
    - Implement RequestPasswordRecovery handler for POST /api/auth/password-recovery
    - Implement ResetPassword handler for POST /api/auth/password-reset
    - Implement Logout handler for POST /api/auth/logout
    - Set request size limit to 1MB
    - Use JSON strict parsing mode
    - Return appropriate HTTP status codes and error messages
    - _Requirements: 1.7, 1.8, 1.9, 2.7, 2.8, 3.8, 6.5, 6.6_
  
  - [ ]* 34.2 Write integration tests for authentication handlers
    - Test complete registration flow with database
    - Test complete login flow with database
    - Test password recovery and reset flows
    - Test error responses for invalid inputs
    - _Requirements: 1.7-1.9, 2.7, 2.8_

- [ ] 35. Wire backend components together
  - [ ] 35.1 Set up dependency injection and routing
    - Initialize database connection pool
    - Create repository instances
    - Create service instances with dependencies
    - Create handler instances with services
    - Set up router with middleware chain: RateLimiter → InputSanitizer → AuthMiddleware (for protected routes)
    - Register all authentication endpoints
    - _Requirements: 5.1, 6.7, 6.8_
  
  - [ ] 35.2 Update main.go to initialize authentication system
    - Load configuration from environment variables
    - Initialize database connection
    - Set up authentication routes
    - Start HTTP server with TLS configuration
    - _Requirements: 1.6, 2.6, 4.10_

- [ ] 36. Checkpoint - Backend API complete
  - Run all backend tests (unit, integration, property tests)
  - Test all API endpoints with curl or Postman
  - Verify middleware chain works correctly
  - Ensure all tests pass, ask the user if questions arise


### Phase 7: Database Schema & Migrations

- [ ] 37. Create database schema for authentication
  - [ ] 37.1 Create migration for password_reset_tokens table
    - Create table with columns: id, user_id, token, expires_at, created_at
    - Add foreign key constraint to users table with ON DELETE CASCADE
    - Create index on token column
    - Create index on expires_at column for cleanup queries
    - _Requirements: 10.2, 10.4_
  
  - [ ] 37.2 Create migration for auth_audit_log table
    - Create table with columns: id, event_type, email, ip_address, success, error_message, created_at
    - Create index on created_at for time-based queries
    - Create index on email for user-based queries
    - Create index on ip_address for IP-based queries
    - _Requirements: 10.3_
  
  - [ ] 37.3 Update users table if needed
    - Verify unique index on email column exists
    - Verify password_hash column exists and is properly sized
    - Add any missing columns or constraints
    - _Requirements: 10.1, 10.3_

- [ ] 38. Create database cleanup jobs
  - [ ] 38.1 Implement scheduled job for expired token cleanup
    - Create function to delete tokens where expires_at < NOW()
    - Schedule to run hourly
    - Log cleanup statistics
    - _Requirements: 10.6_
  
  - [ ] 38.2 Implement scheduled job for audit log archival
    - Create function to archive/delete logs older than 90 days
    - Schedule to run daily
    - Log archival statistics
    - _Requirements: 6.10_

- [ ] 39. Checkpoint - Database schema complete
  - Run all migrations on test database
  - Verify all tables, indexes, and constraints are created
  - Test cleanup jobs
  - Ensure all tests pass, ask the user if questions arise


### Phase 8: Integration & End-to-End Testing

- [ ] 40. Implement mobile-backend integration
  - [ ] 40.1 Configure API base URL and HTTPS settings
    - Set up environment-specific configuration (dev, staging, prod)
    - Configure TLS certificate validation
    - Set up HTTP client with connection pooling and compression
    - _Requirements: 1.5, 2.3_
  
  - [ ] 40.2 Test complete registration flow end-to-end
    - Test mobile app → backend API → database → response → token storage → navigation
    - Test with valid data
    - Test with duplicate email
    - Test with invalid data
    - _Requirements: 1.5-1.11_
  
  - [ ] 40.3 Test complete login flow end-to-end
    - Test mobile app → backend API → database → response → token storage → navigation
    - Test with valid credentials
    - Test with invalid credentials
    - Test with non-existent email
    - _Requirements: 2.3-2.10_
  
  - [ ] 40.4 Test complete password recovery and reset flow end-to-end
    - Test recovery request → token generation → email (logged) → reset screen → password update
    - Test with valid email
    - Test with non-existent email (should still return 200)
    - Test with expired token
    - Test with invalid token
    - _Requirements: 3.3-3.16_

- [ ] 41. Implement session management integration
  - [ ] 41.1 Test session persistence across app restarts
    - Test app restart with valid token → navigate to home
    - Test app restart with expired token → navigate to login
    - Test app restart with no token → navigate to login
    - _Requirements: 4.2, 4.3, 4.4, 4.5_
  
  - [ ]* 41.2 Write property tests for session management
    - **Property 16: Session Token Persistence**
    - **Property 17: Token Expiration Validation**
    - **Validates: Requirements 4.1-4.5**

- [ ] 42. Test protected endpoint access
  - [ ] 42.1 Create a test protected endpoint
    - Create /api/test/protected endpoint that requires authentication
    - Return user ID from token claims
    - _Requirements: 5.1, 5.2, 5.7_
  
  - [ ] 42.2 Test protected endpoint access scenarios
    - Test with valid token → 200 OK with user data
    - Test with no token → 401 Unauthorized
    - Test with invalid token → 401 Unauthorized
    - Test with expired token → 401 Unauthorized
    - _Requirements: 5.3, 5.4, 5.5, 5.6_


- [ ] 43. Test error handling and edge cases
  - [ ] 43.1 Test network error scenarios
    - Test offline mode → display offline error
    - Test timeout → display timeout error
    - Test server unreachable → display service unavailable error
    - _Requirements: 7.4, 7.5, 9.1, 9.2_
  
  - [ ]* 43.2 Write property tests for error handling
    - **Property 26: Offline Error Handling**
    - **Validates: Requirements 7.4, 9.2**
  
  - [ ] 43.3 Test rate limiting
    - Send >5 requests in 1 minute from same IP → verify 429 response
    - Wait 1 minute → verify requests allowed again
    - _Requirements: 6.8, 6.9_
  
  - [ ] 43.4 Test input sanitization
    - Send SQL injection patterns → verify sanitized/rejected
    - Send XSS patterns → verify sanitized/rejected
    - _Requirements: 6.7_

- [ ] 44. Test navigation and access control
  - [ ] 44.1 Test unauthenticated access prevention
    - Attempt to access protected screen without token → redirect to login
    - _Requirements: 8.2, 8.3_
  
  - [ ]* 44.2 Write property tests for access control
    - **Property 27: Unauthenticated Access Prevention**
    - **Property 28: Authentication Navigation Stack Cleanup**
    - **Validates: Requirements 8.2, 8.3, 8.5**
  
  - [ ] 44.3 Test navigation stack cleanup
    - Login successfully → verify cannot navigate back to login screen
    - _Requirements: 8.5_

- [ ] 45. Test offline capability
  - [ ] 45.1 Test offline session access
    - Start app offline with valid token → allow access with limited functionality banner
    - Start app offline with expired token → navigate to login
    - _Requirements: 9.4, 9.5_
  
  - [ ]* 45.2 Write property test for offline session access
    - **Property 29: Offline Session Access**
    - **Validates: Requirements 9.4, 9.5**

- [ ] 46. Checkpoint - Integration testing complete
  - Run all integration tests
  - Verify all end-to-end flows work correctly
  - Test all error scenarios
  - Ensure all tests pass, ask the user if questions arise


### Phase 9: Security Hardening & Performance Optimization

- [ ] 47. Implement security enhancements
  - [ ] 47.1 Configure HTTPS/TLS for production
    - Set up TLS 1.3 configuration
    - Configure certificate validation
    - Enforce HTTPS in production environment
    - _Requirements: 1.5, 2.3_
  
  - [ ] 47.2 Secure JWT secret management
    - Store JWT secret in environment variable
    - Use 256-bit random value
    - Document secret rotation procedure
    - _Requirements: 2.6, 4.10_
  
  - [ ] 47.3 Implement security headers
    - Add Content-Security-Policy header
    - Add X-Content-Type-Options header
    - Add X-Frame-Options header
    - Add Strict-Transport-Security header
    - _Requirements: Security best practices_

- [ ] 48. Optimize resource usage
  - [ ] 48.1 Optimize database queries
    - Verify all queries use prepared statements
    - Verify indexes are used for all lookups
    - Test query performance under load
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  
  - [ ] 48.2 Optimize mobile app performance
    - Implement request/response compression (gzip)
    - Optimize HTTP client connection pooling
    - Minimize payload sizes (only required fields)
    - Cache authentication state to avoid repeated storage reads
    - _Requirements: 1.5, 2.3_
  
  - [ ] 48.3 Optimize backend performance
    - Verify bcrypt operations run in goroutines
    - Verify JWT validation caching is working
    - Test connection pooling under load
    - Measure and optimize response times
    - _Requirements: 1.6, 2.5, 4.6_

- [ ] 49. Implement monitoring and logging
  - [ ] 49.1 Set up structured logging
    - Log all authentication events with context
    - Log errors with stack traces
    - Log performance metrics (response times)
    - Ensure no sensitive data (passwords, tokens) in logs
    - _Requirements: 6.10_
  
  - [ ] 49.2 Set up audit log queries
    - Create queries for failed login attempts by IP
    - Create queries for suspicious patterns
    - Create queries for rate limit violations
    - _Requirements: 6.10_

- [ ] 50. Checkpoint - Security and performance complete
  - Run security audit checklist
  - Run performance benchmarks
  - Verify all security measures are in place
  - Ensure all tests pass, ask the user if questions arise


### Phase 10: Final Validation & Documentation

- [ ] 51. Run comprehensive test suite
  - [ ]* 51.1 Run all property-based tests
    - Execute all 30 property tests with 100 iterations each
    - Verify all properties pass
    - Document any failures and fix issues
    - _Validates: All 30 correctness properties_
  
  - [ ] 51.2 Run all unit tests
    - Execute all mobile unit tests (target >75% coverage)
    - Execute all backend unit tests (target >80% coverage)
    - Generate coverage reports
    - _Requirements: All requirements_
  
  - [ ] 51.3 Run all integration tests
    - Execute all end-to-end flow tests
    - Execute all API integration tests
    - Verify all scenarios pass
    - _Requirements: All requirements_

- [ ] 52. Perform security audit
  - [ ] 52.1 Complete security audit checklist
    - Verify passwords never logged or exposed
    - Verify JWT secrets stored securely
    - Verify HTTPS enforced in production
    - Verify rate limiting active on all auth endpoints
    - Verify input sanitization on all endpoints
    - Verify bcrypt cost factor appropriate (12)
    - Verify token expiration enforced
    - Verify audit logging captures all auth events
    - Verify error messages don't leak information
    - Verify database uses parameterized queries
    - _Requirements: 1.6, 2.6, 2.10, 4.6, 4.10, 6.7, 6.8, 6.10_
  
  - [ ] 52.2 Test security scenarios
    - Test SQL injection attempts
    - Test XSS attempts
    - Test brute force attacks (verify rate limiting)
    - Test token tampering
    - _Requirements: 6.7, 6.8, 6.9_

- [ ] 53. Validate performance benchmarks
  - [ ] 53.1 Run load tests
    - Simulate 1000 concurrent users
    - Measure authentication endpoint throughput
    - Verify response times meet targets (registration <500ms p95, login <300ms p95)
    - _Requirements: Performance targets_
  
  - [ ] 53.2 Optimize if needed
    - Address any performance bottlenecks
    - Re-run benchmarks to verify improvements
    - _Requirements: Performance targets_

- [ ] 54. Create documentation
  - [ ] 54.1 Document API endpoints
    - Document all authentication endpoints with request/response examples
    - Document error codes and messages
    - Document rate limiting behavior
    - _Requirements: All API requirements_
  
  - [ ] 54.2 Document mobile integration
    - Document how to integrate authentication in new screens
    - Document how to use AuthProvider and SessionManager
    - Document error handling patterns
    - _Requirements: All mobile requirements_
  
  - [ ] 54.3 Document deployment and configuration
    - Document environment variables
    - Document database migrations
    - Document TLS/HTTPS setup
    - Document JWT secret generation and rotation
    - _Requirements: Deployment requirements_

- [ ] 55. Final checkpoint - Feature complete
  - All tests passing (unit, integration, property-based)
  - Security audit complete
  - Performance benchmarks met
  - Documentation complete
  - Feature ready for production deployment

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties (30 properties total)
- Unit tests validate specific examples, edge cases, and error conditions
- Integration tests validate complete end-to-end flows
- Focus on UX/IA first (Phase 1-3), then backend (Phase 4-6), then integration (Phase 7-10)
