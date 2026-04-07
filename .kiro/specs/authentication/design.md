# Authentication Feature - Technical Design Document

## Overview

The authentication system provides secure user registration, login, password recovery, and session management for the Lubricentros mobile application. This design prioritizes security, resource efficiency, and scalability while maintaining a seamless user experience.

The system implements a JWT-based stateless authentication architecture with the following key characteristics:

- **Security-First Design**: Defense-in-depth with multiple security layers including bcrypt password hashing, JWT token validation, rate limiting, input sanitization, and audit logging
- **Resource Efficiency**: Connection pooling, minimal database queries, and optimized network payloads
- **Scalability**: Stateless backend design enabling horizontal scaling without session affinity requirements
- **Token Rotation**: Refresh tokens are rotated on each use for enhanced security

The authentication flow spans three layers:
1. **Mobile Layer (Flutter)**: User interface, input validation, token storage (⚠️ currently in-memory, needs secure storage)
2. **API Layer (Go + Gin)**: Request validation, authentication logic, JWT generation/validation, and rate limiting
3. **Data Layer (MariaDB)**: User credentials, refresh tokens, password reset tokens, and audit logs

## Current Implementation Status

**Backend (Go + Gin): 100% Complete**
- ✅ All authentication endpoints implemented
- ✅ JWT token generation and validation
- ✅ Refresh token rotation mechanism
- ✅ Password recovery flow with secure tokens
- ✅ Rate limiting (5 req/min on auth endpoints)
- ✅ Input sanitization middleware
- ✅ Audit logging (async, non-blocking)
- ✅ Role-based access control (Customer/Admin)
- ✅ Bcrypt password hashing (cost factor 12)

**Mobile (Flutter): 70% Complete**
- ✅ UI screens (login, register, password recovery)
- ✅ Input validation
- ✅ Loading states
- ⚠️ Token storage (in-memory only - SECURITY RISK)
- ❌ Secure storage implementation (flutter_secure_storage)
- ❌ Backend integration (dev mode active)

**Critical Issues:**
1. **SECURITY**: Tokens stored in memory, lost on app restart
2. **SECURITY**: Hardcoded credentials in auth_service.dart (line 86)
3. **INTEGRATION**: Mobile not connected to backend (dev mode active)

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile App (Flutter)                     │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │ Auth UI Screens│  │ Input        │  │ Secure Storage  │ │
│  │ - Registration │  │ Validation   │  │ (IN-MEMORY)     │ │
│  │ - Login        │  │              │  │ ⚠️ NOT SECURE   │ │
│  │ - Recovery     │  │              │  │                 │ │
│  └────────┬───────┘  └──────┬───────┘  └────────┬────────┘ │
│           │                  │                    │          │
│           └──────────────────┴────────────────────┘          │
│                              │                               │
└──────────────────────────────┼───────────────────────────────┘
                               │ HTTPS/TLS
                               │ REST API
┌──────────────────────────────┼───────────────────────────────┐
│                     Backend API (Go + Gin)                    │
│  ┌────────────────────────────┴─────────────────────────┐   │
│  │              Rate Limiter Middleware                  │   │
│  │         (5 req/min per IP for auth endpoints)         │   │
│  │              ✅ IMPLEMENTED                            │   │
│  └────────────────────────┬───────────────────────────────┘   │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │           Authentication Middleware                   │   │
│  │         (JWT validation for protected routes)         │   │
│  │              ✅ IMPLEMENTED                            │   │
│  └────────────────────────┬───────────────────────────────┘   │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │              Input Sanitization Layer                 │   │
│  │           (SQL injection prevention)                  │   │
│  │              ✅ IMPLEMENTED                            │   │
│  └────────────────────────┬───────────────────────────────┘   │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │              Auth Handlers (Gin)                      │   │
│  │  - POST /auth/register                                │   │
│  │  - POST /auth/login                                   │   │
│  │  - POST /auth/refresh                                 │   │
│  │  - POST /auth/logout                                  │   │
│  │  - POST /auth/logout-all                              │   │
│  │  - POST /auth/password-recovery                       │   │
│  │  - POST /auth/password-reset                          │   │
│  │  - GET  /users/search                                 │   │
│  │              ✅ ALL IMPLEMENTED                        │   │
│  └────────────────────────┬───────────────────────────────┘   │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │              Auth Usecase Layer                       │   │
│  │  - Password hashing (bcrypt, cost=12)                 │   │
│  │  - JWT generation/validation                          │   │
│  │  - Token rotation (refresh tokens)                    │   │
│  │  - Audit logging (async)                              │   │
│  │              ✅ IMPLEMENTED                            │   │
│  └────────────────────────┬───────────────────────────────┘   │
│  ┌────────────────────────┴─────────────────────────────┐   │
│  │              Repository Layer                         │   │
│  │  - UserRepository                                     │   │
│  │  - RefreshTokenRepository                             │   │
│  │  - PasswordResetTokenRepository                       │   │
│  │  - AuditLogRepository                                 │   │
│  │  - Connection pooling                                 │   │
│  │              ✅ IMPLEMENTED                            │   │
│  └────────────────────────┬───────────────────────────────┘   │
└───────────────────────────┼───────────────────────────────────┘
                            │ Connection Pool
                            │ (max 25 connections)
┌───────────────────────────┼───────────────────────────────────┐
│                  MariaDB Database                             │
│  ┌──────────────┐  ┌────────────────────┐  ┌──────────────┐ │
│  │ users        │  │ password_reset_    │  │ auth_audit_  │ │
│  │ - id         │  │ tokens             │  │ log          │ │
│  │ - email      │  │ - user_id          │  │ - event_type │ │
│  │ - password_  │  │ - token            │  │ - email      │ │
│  │   hash       │  │ - expires_at       │  │ - ip_address │ │
│  │ - name       │  │ - created_at       │  │ - success    │ │
│  │ - phone      │  │                    │  │ - error_msg  │ │
│  │ - role       │  │                    │  │ - created_at │ │
│  │ - is_active  │  │                    │  │              │ │
│  │ - created_at │  │                    │  │              │ │
│  │ - updated_at │  │                    │  │              │ │
│  └──────────────┘  └────────────────────┘  └──────────────┘ │
│  ┌──────────────┐                                            │
│  │ refresh_     │                                            │
│  │ tokens       │                                            │
│  │ - id         │                                            │
│  │ - user_id    │                                            │
│  │ - token_hash │                                            │
│  │ - expires_at │                                            │
│  │ - revoked_at │                                            │
│  │ - created_at │                                            │
│  └──────────────┘                                            │
└───────────────────────────────────────────────────────────────┘

**Implementation Status:**
✅ Backend: 100% implemented (Gin framework, all endpoints, security layers)
⚠️ Mobile: 70% implemented (UI complete, but using in-memory storage - NOT SECURE)
❌ Integration: 0% (mobile in dev mode, not connected to backend)
```

### Security Layers

The architecture implements defense-in-depth with multiple security boundaries:

1. **Transport Security**: All communication over HTTPS/TLS 1.3
2. **Rate Limiting**: IP-based throttling at the API gateway level
3. **Input Validation**: Client-side and server-side validation with sanitization
4. **Authentication**: JWT tokens with HMAC-SHA256 signatures
5. **Authorization**: Middleware-based access control for protected endpoints
6. **Data Protection**: Bcrypt password hashing, secure token storage, encrypted database connections
7. **Audit Logging**: All authentication events logged with IP addresses and timestamps

### Component Interaction Flow

**Registration Flow:**
```
User → Mobile UI → Input Validation → API Request (HTTPS) → 
Rate Limiter → Input Sanitization → Auth Handler → 
Password Hashing (bcrypt) → Database Insert → 
JWT Generation → Response → Secure Storage → Home Screen
```

**Login Flow:**
```
User → Mobile UI → Input Validation → API Request (HTTPS) → 
Rate Limiter → Input Sanitization → Auth Handler → 
Database Query → Password Verification (bcrypt) → 
JWT Generation → Response → Secure Storage → Home Screen
```

**Protected Endpoint Access:**
```
Mobile App → API Request + JWT → Auth Middleware → 
JWT Validation → User ID Extraction → Handler Execution → Response
```

## Components and Interfaces

### Backend Components (Go + Gin) - ✅ IMPLEMENTED

#### 1. Auth Handlers
**Responsibility**: HTTP request handling for authentication endpoints

**Implementation Status**: ✅ 100% Complete

**Interface**:
```go
type AuthHandler struct {
    authUsecase *AuthUsecase
}

func (h *AuthHandler) Register(c *gin.Context)
func (h *AuthHandler) Login(c *gin.Context)
func (h *AuthHandler) Refresh(c *gin.Context)
func (h *AuthHandler) Logout(c *gin.Context)
func (h *AuthHandler) LogoutAll(c *gin.Context)
func (h *AuthHandler) RequestPasswordRecovery(c *gin.Context)
func (h *AuthHandler) ResetPassword(c *gin.Context)
func (h *AuthHandler) SearchUsers(c *gin.Context)
```

**Endpoints**:
- `POST /auth/register` - Create new user account
- `POST /auth/login` - Authenticate user
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Revoke single refresh token
- `POST /auth/logout-all` - Revoke all user's refresh tokens
- `POST /auth/password-recovery` - Request password reset
- `POST /auth/password-reset` - Reset password with token
- `GET /users/search?q=query` - Search users (for vehicle transfer)

**Security Measures**:
- Input validation using Gin's binding with struct tags
- Request size limit: 1MB
- JSON parsing with strict mode
- Generic error messages (no information leakage)
- Rate limiting: 5 req/min per IP on auth endpoints

#### 1. AuthenticationService
**Responsibility**: Manages authentication state and API communication

**Interface**:
```dart
class AuthenticationService {
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  });
  
  Future<AuthResult> login({
    required String email,
    required String password,
  });
  
  Future<void> logout();
  
  Future<bool> requestPasswordRecovery(String email);
  
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  });
  
  Future<bool> isAuthenticated();
  
  Future<String?> getToken();
  
  Stream<AuthState> get authStateStream;
}
```

**Security Considerations**:
- All API calls use HTTPS
- Tokens stored using flutter_secure_storage (Keychain on iOS, KeyStore on Android)
- Automatic token expiration handling
- Network timeout: 30 seconds

**Resource Optimization**:
- HTTP client connection pooling
- Request/response compression (gzip)
- Minimal payload sizes (only required fields)
- Cached authentication state to avoid repeated storage reads

#### 2. InputValidator
**Responsibility**: Client-side input validation and sanitization

**Interface**:
```dart
class InputValidator {
  ValidationResult validateEmail(String email);
  ValidationResult validatePassword(String password);
  ValidationResult validatePasswordMatch(String password, String confirmation);
  ValidationResult validateName(String name);
  PasswordStrength calculatePasswordStrength(String password);
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
}

enum PasswordStrength { weak, medium, strong }
```

**Validation Rules**:
- Email: RFC 5322 format
- Password: ≥8 chars, 1 uppercase, 1 lowercase, 1 number
- Name: ≥2 chars
- Real-time validation with debouncing (300ms) to reduce CPU usage

#### 3. SecureStorageService
**Responsibility**: Secure token and credential storage

**Interface**:
```dart
class SecureStorageService {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> saveUserData(UserData userData);
  Future<UserData?> getUserData();
  Future<void> clearAll();
}
```

**Security Implementation**:
- Uses flutter_secure_storage
- iOS: Keychain with kSecAttrAccessibleAfterFirstUnlock
- Android: EncryptedSharedPreferences with AES-256
- No tokens in memory longer than necessary

#### 4. SessionManager
**Responsibility**: Session lifecycle management

**Interface**:
```dart
class SessionManager {
  Future<void> initializeSession();
  Future<bool> validateSession();
  Future<void> refreshSession();
  Future<void> terminateSession();
  bool isTokenExpired(String token);
  Duration getTokenRemainingTime(String token);
}
```

**Resource Optimization**:
- Token expiration checked locally before API calls
- Session state cached in memory
- Automatic cleanup on logout

#### 5. UI Screens

**RegistrationScreen**:
- Email, password, password confirmation, name, phone (optional) inputs
- Real-time validation feedback
- Password strength indicator
- Loading state during registration
- Error display
- Navigation to login

**LoginScreen**:
- Email and password inputs
- Remember me option (default: true)
- Loading state during login
- Error display
- Navigation to registration and password recovery

**PasswordRecoveryScreen**:
- Email input
- Success message display
- Navigation back to login

**PasswordResetScreen**:
- New password and confirmation inputs
- Password strength indicator
- Success/error handling

### Backend Components (Go)

#### 1. Auth Handlers
**Responsibility**: HTTP request handling for authentication endpoints

**Interface**:
```go
type AuthHandler struct {
    authService *AuthService
    logger      *Logger
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request)
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request)
func (h *AuthHandler) RequestPasswordRecovery(w http.ResponseWriter, r *http.Request)
func (h *AuthHandler) ResetPassword(w http.ResponseWriter, r *http.Request)
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request)
```

**Request/Response Models**:
```go
type RegisterRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required,min=8"`
    Name     string `json:"name" validate:"required,min=2"`
    Phone    string `json:"phone,omitempty"`
}

type LoginRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required"`
}

type AuthResponse struct {
    Token string   `json:"token"`
    User  UserData `json:"user"`
}

type UserData struct {
    ID    int    `json:"id"`
    Email string `json:"email"`
    Name  string `json:"name"`
    Phone string `json:"phone,omitempty"`
}
```

**Security Measures**:
- Input validation using go-playground/validator
- Request size limit: 1MB
- JSON parsing with strict mode
- Generic error messages (no information leakage)

#### 2. AuthService
**Responsibility**: Core authentication business logic

**Interface**:
```go
type AuthService struct {
    userRepo    UserRepository
    tokenRepo   TokenRepository
    jwtSecret   []byte
    bcryptCost  int
    tokenExpiry time.Duration
}

func (s *AuthService) RegisterUser(req RegisterRequest) (*AuthResponse, error)
func (s *AuthService) AuthenticateUser(req LoginRequest) (*AuthResponse, error)
func (s *AuthService) GeneratePasswordResetToken(email string) (string, error)
func (s *AuthService) ResetPassword(token, newPassword string) error
func (s *AuthService) ValidateToken(tokenString string) (*Claims, error)
func (s *AuthService) GenerateJWT(userID int) (string, error)
```

**Security Configuration**:
- Bcrypt cost factor: 12 (balances security and performance)
- JWT expiration: 24 hours
- Password reset token expiration: 1 hour
- JWT algorithm: HS256 (HMAC-SHA256)

**Resource Optimization**:
- Bcrypt operations run in goroutines to avoid blocking
- JWT validation cached for 5 minutes (in-memory LRU cache, max 1000 entries)
- Database connection reuse via repository pattern

#### 3. Middleware

**RateLimiterMiddleware**:
```go
type RateLimiterMiddleware struct {
    limiter *rate.Limiter
    store   map[string]*rate.Limiter
    mu      sync.RWMutex
}

func (m *RateLimiterMiddleware) Limit(next http.Handler) http.Handler
```

**Configuration**:
- 5 requests per minute per IP for auth endpoints
- Token bucket algorithm
- Cleanup of stale entries every 10 minutes

**AuthMiddleware**:
```go
type AuthMiddleware struct {
    authService *AuthService
}

func (m *AuthMiddleware) RequireAuth(next http.Handler) http.Handler
```

**Functionality**:
- Extract JWT from Authorization header (Bearer scheme)
- Validate JWT signature and expiration
- Extract user ID and add to request context
- Return 401 for invalid/missing tokens

**InputSanitizerMiddleware**:
```go
type InputSanitizerMiddleware struct{}

func (m *InputSanitizerMiddleware) Sanitize(next http.Handler) http.Handler
```

**Sanitization**:
- HTML entity encoding
- SQL injection pattern detection
- Trim whitespace
- Normalize Unicode

#### 4. Repository Layer

**UserRepository**:
```go
type UserRepository interface {
    Create(user *User) error
    FindByEmail(email string) (*User, error)
    FindByID(id int) (*User, error)
    UpdatePassword(userID int, passwordHash string) error
    EmailExists(email string) (bool, error)
}

type PostgresUserRepository struct {
    db *sql.DB
}
```

**TokenRepository**:
```go
type TokenRepository interface {
    CreatePasswordResetToken(userID int, token string, expiresAt time.Time) error
    FindPasswordResetToken(token string) (*PasswordResetToken, error)
    DeletePasswordResetToken(token string) error
    DeleteExpiredTokens() error
}

type PostgresTokenRepository struct {
    db *sql.DB
}
```

**Resource Optimization**:
- Prepared statements for all queries
- Connection pooling (max 25 connections, max 5 idle)
- Query timeout: 5 seconds
- Indexes on email and token columns

#### 5. AuditLogger
**Responsibility**: Security event logging

**Interface**:
```go
type AuditLogger struct {
    db *sql.DB
}

func (l *AuditLogger) LogAuthEvent(eventType, email, ipAddress string, success bool)
```

**Logged Events**:
- Registration attempts (success/failure)
- Login attempts (success/failure)
- Password recovery requests
- Password resets
- Token validation failures
- Rate limit violations

## Data Models

### Database Schema

#### users table
```sql
CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    role ENUM('customer', 'admin') NOT NULL DEFAULT 'customer',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);
```

**Security Considerations**:
- Email uniqueness enforced at database level
- Password stored as bcrypt hash (never plaintext)
- No sensitive data in logs
- Role-based access control (customer/admin)

#### refresh_tokens table
```sql
CREATE TABLE refresh_tokens (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
```

**Token Management**:
- Tokens stored as SHA-256 hashes (not plaintext)
- Automatic expiration (7 days)
- Token rotation on each refresh
- Revocation support for logout/logout-all

#### password_reset_tokens table
```sql
CREATE TABLE password_reset_tokens (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_password_reset_tokens_token ON password_reset_tokens(token);
CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens(user_id);
CREATE INDEX idx_password_reset_tokens_expires_at ON password_reset_tokens(expires_at);
```

**Token Generation**:
- Cryptographically secure random token (32 bytes, hex-encoded = 64 chars)
- One-time use (deleted after successful reset)
- 1-hour expiration
- Automatic cleanup of expired tokens via scheduled job

#### auth_audit_log table
```sql
CREATE TABLE auth_audit_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    ip_address VARCHAR(45) NOT NULL,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auth_audit_log_created_at ON auth_audit_log(created_at);
CREATE INDEX idx_auth_audit_log_email ON auth_audit_log(email);
CREATE INDEX idx_auth_audit_log_ip ON auth_audit_log(ip_address);
CREATE INDEX idx_auth_audit_log_event_type ON auth_audit_log(event_type);
```

**Event Types**:
- `registration`
- `login`
- `logout`
- `refresh`
- `password_recovery`
- `password_reset`
- `token_validation_failure`

**Retention Policy**:
- Keep logs for 90 days
- Automated archival/deletion via scheduled job

### JWT Token Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "user_id": 123,
    "email": "user@example.com",
    "role": "customer",
    "iat": 1234567890,
    "exp": 1234654290
  },
  "signature": "HMAC-SHA256(header.payload, secret)"
}
```

**Claims**:
- `user_id`: User ID (subject)
- `email`: User email (for convenience, not for authentication)
- `role`: User role (customer/admin) for authorization
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp

**Token Types**:
- **Access Token**: 15 minutes expiration (900 seconds)
- **Refresh Token**: 7 days expiration (604800 seconds)

**Security**:
- Secret key: 256-bit random value stored in environment variable (JWT_SECRET)
- Signature prevents tampering
- Expiration enforced on every validation
- No sensitive data in payload (it's base64-encoded, not encrypted)
- Refresh tokens stored as SHA-256 hashes in database
- Token rotation: old refresh token revoked when new one issued

### Data Flow Diagrams

#### Registration Data Flow
```
[Mobile App]
    ↓ (1) POST /api/auth/register
    ↓     {email, password, name, phone}
    ↓     HTTPS/TLS
[Rate Limiter]
    ↓ (2) Check: <5 req/min from IP?
[Input Sanitizer]
    ↓ (3) Sanitize all string inputs
[Auth Handler]
    ↓ (4) Validate request structure
[Auth Service]
    ↓ (5) Check email uniqueness
    ↓     [UserRepository → PostgreSQL]
    ↓ (6) Hash password (bcrypt, cost=12)
    ↓ (7) Insert user record
    ↓     [UserRepository → PostgreSQL]
    ↓ (8) Generate JWT token
    ↓ (9) Log success event
    ↓     [AuditLogger → PostgreSQL]
    ↓ (10) Return {token, user}
[Mobile App]
    ↓ (11) Store token in secure storage
    ↓ (12) Navigate to home screen
```

#### Login Data Flow
```
[Mobile App]
    ↓ (1) POST /api/auth/login
    ↓     {email, password}
    ↓     HTTPS/TLS
[Rate Limiter]
    ↓ (2) Check: <5 req/min from IP?
[Input Sanitizer]
    ↓ (3) Sanitize inputs
[Auth Handler]
    ↓ (4) Validate request structure
[Auth Service]
    ↓ (5) Query user by email
    ↓     [UserRepository → PostgreSQL]
    ↓ (6) Compare password with hash (bcrypt)
    ↓ (7) If valid: Generate JWT token
    ↓ (8) Log login attempt
    ↓     [AuditLogger → PostgreSQL]
    ↓ (9) Return {token, user} or 401
[Mobile App]
    ↓ (10) Store token in secure storage
    ↓ (11) Navigate to home screen
```

#### Protected Endpoint Access
```
[Mobile App]
    ↓ (1) GET /api/vehicles
    ↓     Authorization: Bearer <JWT>
    ↓     HTTPS/TLS
[Auth Middleware]
    ↓ (2) Extract JWT from header
    ↓ (3) Validate JWT signature
    ↓ (4) Check expiration
    ↓ (5) Extract user ID from claims
    ↓ (6) Add user ID to request context
[Protected Handler]
    ↓ (7) Access user ID from context
    ↓ (8) Execute business logic
    ↓ (9) Return response
[Mobile App]
    ↓ (10) Process response
```

### Resource Optimization Strategies

**Database**:
- Connection pooling: max 25 connections, max 5 idle, 5-minute max lifetime
- Prepared statements cached per connection
- Query timeout: 5 seconds
- Indexes on all foreign keys and frequently queried columns
- Batch deletion of expired tokens (once per hour)

**Memory**:
- JWT validation cache: LRU, max 1000 entries, 5-minute TTL
- Rate limiter: Cleanup stale entries every 10 minutes
- HTTP client connection pooling: max 100 idle connections
- Request body size limit: 1MB

**Network**:
- Response compression (gzip) for responses >1KB
- Minimal JSON payloads (only required fields)
- HTTP/2 support for multiplexing
- Keep-alive connections

**CPU**:
- Bcrypt operations in goroutines (non-blocking)
- JWT validation cached to avoid repeated HMAC computation
- Efficient regex patterns for input validation
- Rate limiter uses token bucket (O(1) operations)

**Mobile Battery**:
- Batch API calls when possible
- Local token expiration check before API call
- Exponential backoff for failed requests
- No background token refresh (only on-demand)


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property Reflection

After analyzing all acceptance criteria, I identified several areas of redundancy:

1. **Email validation** appears in registration (1.2), login (2.2), and password recovery (3.2) - these can be consolidated into a single property
2. **Password validation** (strength and matching) appears in registration (1.3, 1.4) and password reset (3.11) - can be consolidated
3. **Loading state display** appears across multiple flows (1.5, 2.3, 3.3) - can be generalized
4. **Token storage after authentication** appears for both registration (1.10) and login (2.9) - can be consolidated
5. **JWT validation** appears in session management (4.6) and protected endpoints (5.1-5.6) - overlapping concerns
6. **UI element presence** (1.1, 1.12, 2.1, 2.11, 2.12, 3.1, 8.1, 10.1-10.4) are examples, not properties
7. **Visual consistency** requirements (7.10, 8.6, 8.7, 8.8) are not programmatically testable

The following properties represent the unique, testable correctness requirements after eliminating redundancy:

### Property 1: Email Format Validation

For any string input to an email field, the Input_Validator should accept it if and only if it matches RFC 5322 email format.

**Validates: Requirements 1.2, 2.2, 3.2, 6.1**

### Property 2: Password Strength Validation

For any password input, the Input_Validator should reject it if it is less than 8 characters OR lacks an uppercase letter OR lacks a lowercase letter OR lacks a number.

**Validates: Requirements 1.3, 6.2, 6.3**

### Property 3: Password Confirmation Matching

For any pair of password and confirmation inputs, the Input_Validator should accept them if and only if they are identical strings.

**Validates: Requirements 1.4, 3.11**

### Property 4: Name Length Validation

For any name input, the Input_Validator should reject it if it is less than 2 characters long.

**Validates: Requirements 6.4**

### Property 5: Bcrypt Password Hashing

For any successful user registration or password reset, the password stored in the database should be a valid bcrypt hash, not the plaintext password.

**Validates: Requirements 1.6, 3.13**

### Property 6: Unique Email Registration

For any registration request with an email that already exists in the database, the Backend_API should return a 409 Conflict error and not create a duplicate user record.

**Validates: Requirements 1.8**

### Property 7: Successful Registration Response

For any successful registration with a unique email and valid data, the Backend_API should return a 201 Created status with a valid JWT token and user data (id, email, name, phone).

**Validates: Requirements 1.9**

### Property 8: Registration Token Storage

For any successful registration, the returned JWT token should be stored in secure storage and the app should navigate to the home screen.

**Validates: Requirements 1.10, 2.9**

### Property 9: Login Credential Verification

For any login attempt, the Backend_API should verify the email exists and compare the provided password with the stored bcrypt hash, returning 200 with a token if valid or 401 if invalid.

**Validates: Requirements 2.4, 2.5, 2.7, 2.8**

### Property 10: Login Error Message Opacity

For any failed login attempt, the error message should be generic and not reveal whether the email or password was incorrect.

**Validates: Requirements 2.10**

### Property 11: JWT Token Structure

For any generated JWT token (registration or login), it should contain valid claims including user ID (sub), email, issued-at timestamp (iat), and expiration timestamp (exp) set to 24 hours from issuance, and be signed with HMAC-SHA256.

**Validates: Requirements 2.6, 4.10**

### Property 12: Password Recovery Token Generation

For any password recovery request with an existing email, the Backend_API should generate a cryptographically secure unique token with 1-hour expiration and store it in the database associated with the user.

**Validates: Requirements 3.5, 3.6**

### Property 13: Password Recovery Email Timing Attack Prevention

For any password recovery request, the Backend_API should return 200 OK regardless of whether the email exists in the database, preventing email enumeration.

**Validates: Requirements 3.8**

### Property 14: Password Reset Token Validation

For any password reset request, the Backend_API should verify the token exists, is associated with a user, and has not expired before allowing the password change.

**Validates: Requirements 3.12**

### Property 15: Password Reset Token Invalidation

For any successful password reset, the recovery token should be deleted from the database, preventing reuse.

**Validates: Requirements 3.14, 10.5**

### Property 16: Session Token Persistence

For any successful authentication (registration or login), the JWT token should be stored in secure local storage and retrieved on app restart.

**Validates: Requirements 4.1, 4.2**

### Property 17: Token Expiration Validation

For any stored JWT token, the Session_Manager should validate that it is not expired before using it, and clear it if expired.

**Validates: Requirements 4.3, 4.5**

### Property 18: JWT Signature Validation

For any request to a protected endpoint with a JWT token, the Backend_API should validate the JWT signature and expiration, returning 401 if invalid or expired.

**Validates: Requirements 4.6, 4.7, 5.5, 5.6**

### Property 19: Session Cleanup on Logout

For any logout action, the Session_Manager should clear the stored JWT token from secure storage and navigate to the login screen.

**Validates: Requirements 4.8, 4.9**

### Property 20: Protected Endpoint Access Control

For any request to a protected endpoint, the Backend_API should return 401 if the request lacks a valid JWT token, and should allow the request to proceed with user ID in context if the token is valid.

**Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.7**

### Property 21: Input Validation Before Processing

For any API request with invalid input data (email format, password strength, name length), the Backend_API should return 400 Bad Request with specific field errors before processing the request.

**Validates: Requirements 6.5, 6.6**

### Property 22: SQL Injection Prevention

For any text input containing SQL injection patterns (e.g., `'; DROP TABLE users; --`), the Backend_API should sanitize or reject the input, preventing SQL injection attacks.

**Validates: Requirements 6.7**

### Property 23: Rate Limiting Enforcement

For any IP address making more than 5 requests to authentication endpoints within a 1-minute window, the Backend_API should return 429 Too Many Requests for subsequent requests.

**Validates: Requirements 6.8, 6.9**

### Property 24: Authentication Audit Logging

For any failed authentication attempt (registration, login, password recovery, password reset), the Backend_API should create an audit log entry with event type, email, IP address, timestamp, and success status.

**Validates: Requirements 6.10**

### Property 25: Form Validation State Management

For any authentication form, the submit button should be disabled when validation fails and enabled when all fields are valid.

**Validates: Requirements 7.7, 7.8**

### Property 26: Offline Error Handling

For any authentication operation attempted without network connectivity, the Error_Handler should display a specific offline error message.

**Validates: Requirements 7.4, 9.2**

### Property 27: Unauthenticated Access Prevention

For any attempt to access a protected screen without a valid JWT token, the Mobile_App should prevent access and navigate to the login screen.

**Validates: Requirements 8.2, 8.3**

### Property 28: Authentication Navigation Stack Cleanup

For any successful authentication, the Mobile_App should clear the authentication navigation stack, preventing back navigation to login/registration screens.

**Validates: Requirements 8.5**

### Property 29: Offline Session Access

For any app startup with a valid (non-expired) JWT token in secure storage, the Session_Manager should allow access to the app even when offline, displaying a limited functionality banner.

**Validates: Requirements 9.4, 9.5**

### Property 30: Expired Token Cleanup

For any scheduled cleanup job execution, the Backend_API should delete all password reset tokens where expires_at is in the past.

**Validates: Requirements 10.6**

## Error Handling

### Error Categories

**Client-Side Errors (Mobile App)**:

1. **Validation Errors**
   - Display inline below the relevant field
   - Red text with error icon
   - Clear on field edit
   - Examples: "Invalid email format", "Password must be at least 8 characters"

2. **Network Errors**
   - Offline: "No internet connection. Please check your network settings."
   - Timeout: "Request timed out. Please try again."
   - Server unreachable: "Unable to connect to server. Please try again later."
   - Display as banner at top of screen
   - Retry button for transient errors

3. **Authentication Errors**
   - Generic message: "Invalid email or password" (for login)
   - "Email already registered" (for registration)
   - "Invalid or expired reset link" (for password reset)
   - Display below submit button
   - Maintain form data for retry

4. **Session Errors**
   - "Your session has expired. Please log in again."
   - Display as modal dialog
   - Auto-navigate to login screen after dismissal

**Server-Side Errors (Backend API)**:

1. **400 Bad Request**
   - Invalid input data
   - Response format:
   ```json
   {
     "error": "Validation failed",
     "fields": {
       "email": "Invalid email format",
       "password": "Password must be at least 8 characters"
     }
   }
   ```

2. **401 Unauthorized**
   - Invalid credentials
   - Missing or invalid JWT token
   - Expired JWT token
   - Response format:
   ```json
   {
     "error": "Unauthorized",
     "message": "Invalid or expired token"
   }
   ```

3. **409 Conflict**
   - Duplicate email registration
   - Response format:
   ```json
   {
     "error": "Conflict",
     "message": "Email already registered"
   }
   ```

4. **429 Too Many Requests**
   - Rate limit exceeded
   - Response format:
   ```json
   {
     "error": "Too many requests",
     "message": "Please try again in 60 seconds",
     "retry_after": 60
   }
   ```

5. **500 Internal Server Error**
   - Database connection failure
   - Unexpected errors
   - Response format:
   ```json
   {
     "error": "Internal server error",
     "message": "An unexpected error occurred. Please try again later."
   }
   ```
   - Log full error details server-side
   - Never expose internal details to client

### Error Handling Strategies

**Retry Logic**:
- Automatic retry for network timeouts: 3 attempts with exponential backoff (1s, 2s, 4s)
- User-initiated retry for server errors
- No automatic retry for 4xx errors (client errors)

**Error Recovery**:
- Maintain form state on error
- Clear sensitive data (passwords) on 401 errors
- Provide clear next steps in error messages
- Offer alternative actions (e.g., "Forgot password?" on login error)

**Logging**:
- Client-side: Log errors to local storage for debugging (non-sensitive data only)
- Server-side: Log all errors with full context (request ID, user ID, stack trace)
- Audit log: All authentication events (success and failure)

**Security Considerations**:
- Never reveal whether an email exists in error messages (except registration)
- Use generic messages for authentication failures
- Rate limit error responses to prevent enumeration attacks
- Log suspicious patterns (repeated failures from same IP)

## Testing Strategy

### Dual Testing Approach

The authentication feature requires both unit tests and property-based tests for comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, error conditions, and integration points
- **Property-based tests**: Verify universal properties across all inputs with randomized test data

Both approaches are complementary and necessary. Unit tests catch concrete bugs in specific scenarios, while property-based tests verify general correctness across a wide input space.

### Property-Based Testing

**Library Selection**:
- **Flutter/Dart**: Use `test` package with custom property-based testing helpers or `faker` for data generation
- **Go**: Use `gopter` (property-based testing library for Go)

**Configuration**:
- Minimum 100 iterations per property test (due to randomization)
- Each property test must reference its design document property
- Tag format: `Feature: authentication, Property {number}: {property_text}`

**Property Test Examples**:

```go
// Go example using gopter
func TestProperty1_EmailFormatValidation(t *testing.T) {
    // Feature: authentication, Property 1: Email Format Validation
    properties := gopter.NewProperties(nil)
    
    properties.Property("valid emails are accepted", prop.ForAll(
        func(email string) bool {
            // Generate valid RFC 5322 email
            validator := NewInputValidator()
            result := validator.ValidateEmail(email)
            return result.IsValid
        },
        genValidEmail(),
    ))
    
    properties.Property("invalid emails are rejected", prop.ForAll(
        func(invalidEmail string) bool {
            validator := NewInputValidator()
            result := validator.ValidateEmail(invalidEmail)
            return !result.IsValid
        },
        genInvalidEmail(),
    ))
    
    properties.TestingRun(t, gopter.ConsoleReporter(false))
}
```

```dart
// Dart example with custom property testing
void main() {
  group('Property 1: Email Format Validation', () {
    // Feature: authentication, Property 1: Email Format Validation
    test('valid emails are accepted', () {
      final validator = InputValidator();
      
      for (int i = 0; i < 100; i++) {
        final email = generateValidEmail();
        final result = validator.validateEmail(email);
        expect(result.isValid, isTrue, 
          reason: 'Valid email $email should be accepted');
      }
    });
    
    test('invalid emails are rejected', () {
      final validator = InputValidator();
      
      for (int i = 0; i < 100; i++) {
        final email = generateInvalidEmail();
        final result = validator.validateEmail(email);
        expect(result.isValid, isFalse,
          reason: 'Invalid email $email should be rejected');
      }
    });
  });
}
```

**Property Test Coverage**:
- All 30 correctness properties should have corresponding property-based tests
- Focus on input validation, authentication flows, token management, and access control
- Use generators for: emails, passwords, names, tokens, user data, timestamps

### Unit Testing

**Unit Test Focus**:
- Specific examples demonstrating correct behavior
- Edge cases (empty strings, null values, boundary conditions)
- Error conditions (network failures, database errors)
- Integration points (API endpoints, database operations)
- UI state transitions

**Unit Test Examples**:

```go
// Go unit test example
func TestRegisterHandler_DuplicateEmail(t *testing.T) {
    // Setup
    db := setupTestDB(t)
    defer db.Close()
    
    // Create existing user
    existingUser := &User{
        Email: "test@example.com",
        PasswordHash: "hash",
        Name: "Test User",
    }
    userRepo := NewPostgresUserRepository(db)
    userRepo.Create(existingUser)
    
    // Attempt duplicate registration
    handler := NewAuthHandler(NewAuthService(userRepo, nil, []byte("secret"), 12, 24*time.Hour))
    req := httptest.NewRequest("POST", "/api/auth/register", 
        strings.NewReader(`{"email":"test@example.com","password":"Password123","name":"Another User"}`))
    w := httptest.NewRecorder()
    
    handler.Register(w, req)
    
    // Assert
    assert.Equal(t, http.StatusConflict, w.Code)
    assert.Contains(t, w.Body.String(), "Email already registered")
}
```

```dart
// Dart unit test example
void main() {
  group('AuthenticationService', () {
    test('login with invalid credentials returns error', () async {
      final mockClient = MockHttpClient();
      when(mockClient.post(any, body: any, headers: any))
        .thenAnswer((_) async => http.Response(
          '{"error":"Unauthorized","message":"Invalid credentials"}',
          401,
        ));
      
      final authService = AuthenticationService(client: mockClient);
      final result = await authService.login(
        email: 'test@example.com',
        password: 'wrongpassword',
      );
      
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Invalid credentials'));
    });
  });
}
```

**Unit Test Coverage Goals**:
- Backend: >80% code coverage
- Mobile: >75% code coverage
- Focus on critical paths: authentication flows, token validation, error handling

### Integration Testing

**API Integration Tests**:
- Test complete authentication flows end-to-end
- Use real database (test instance) and real HTTP server
- Test scenarios:
  - Complete registration flow
  - Complete login flow
  - Complete password recovery flow
  - Token expiration and refresh
  - Rate limiting behavior
  - Concurrent requests

**Mobile Integration Tests**:
- Test UI flows with mocked backend
- Test secure storage integration
- Test navigation flows
- Test offline behavior

### Security Testing

**Penetration Testing Scenarios**:
- SQL injection attempts
- XSS attempts
- CSRF attempts
- Brute force attacks (verify rate limiting)
- Token tampering
- Session hijacking attempts

**Security Audit Checklist**:
- [x] Passwords never logged or exposed
- [ ] JWT secrets stored securely (environment variables)
- [ ] HTTPS enforced in production
- [ ] Rate limiting active on all auth endpoints
- [ ] Input sanitization on all endpoints
- [ ] Bcrypt cost factor appropriate (12)
- [ ] Token expiration enforced
- [ ] Audit logging captures all auth events
- [ ] Error messages don't leak information
- [ ] Database uses parameterized queries

### Performance Testing

**Load Testing**:
- Simulate 1000 concurrent users
- Test authentication endpoint throughput
- Measure response times under load
- Verify rate limiting doesn't affect legitimate users

**Performance Benchmarks**:
- Registration: <500ms (p95)
- Login: <300ms (p95)
- Token validation: <50ms (p95)
- Password hashing: <200ms (bcrypt cost 12)

### Test Data Management

**Test Data Generators**:
- Valid emails: `user{random}@{domain}.com`
- Invalid emails: missing @, invalid characters, too long
- Valid passwords: mix of upper, lower, numbers, 8-20 chars
- Invalid passwords: too short, missing requirements
- Valid names: 2-50 chars, various character sets
- JWT tokens: valid structure, expired, invalid signature
- Recovery tokens: valid format, expired, invalid

**Test Database**:
- Separate test database instance
- Reset between test runs
- Seed with known test data for integration tests
- Use transactions for unit tests (rollback after each test)

### Continuous Integration

**CI Pipeline**:
1. Run unit tests (both backend and mobile)
2. Run property-based tests (100 iterations each)
3. Run integration tests
4. Run security tests (static analysis)
5. Generate coverage reports
6. Fail build if coverage <80% (backend) or <75% (mobile)

**Test Execution Time**:
- Unit tests: <2 minutes
- Property-based tests: <5 minutes
- Integration tests: <3 minutes
- Total CI time: <10 minutes



---

## Critical Recommendations

### Immediate Actions Required (P0 - CRITICAL)

#### 1. Implement Secure Token Storage (Mobile)
**Current State**: Tokens stored in memory, lost on app restart  
**Risk**: Users must re-login every time app restarts, poor UX, security vulnerability  
**Action**: Implement `flutter_secure_storage`
```dart
// Add to pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0

// Implement SecureStorageService
class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: 'access_token');
  }
}
```
**Estimated Time**: 2-3 hours  
**Priority**: CRITICAL

#### 2. Remove Hardcoded Credentials
**Current State**: Hardcoded credentials in `mobile/lib/services/auth_service.dart` line 86  
**Risk**: Security vulnerability, credentials exposed in source code  
**Action**: Remove hardcoded credentials immediately
```dart
// REMOVE THIS:
// const String _devPassword = "Admin123";

// Use environment variables or secure configuration instead
```
**Estimated Time**: 5 minutes  
**Priority**: CRITICAL

#### 3. Connect Mobile to Backend
**Current State**: Mobile in dev mode, using mock data  
**Risk**: App not functional with real backend  
**Action**: 
1. Disable dev mode in AuthService
2. Configure API base URL from environment
3. Test all authentication flows
4. Handle network errors properly

**Estimated Time**: 4-6 hours  
**Priority**: CRITICAL

### High Priority Actions (P1)

#### 4. Increase Test Coverage
**Current State**: 35% backend, 50% mobile  
**Target**: 80% backend, 75% mobile  
**Action**: 
- Add repository tests
- Add handler integration tests
- Add mobile service tests
- Add E2E tests

**Estimated Time**: 10-15 hours  
**Priority**: HIGH

#### 5. Implement Email Integration
**Current State**: Password recovery tokens logged to console  
**Risk**: Password recovery not functional  
**Action**: Integrate SendGrid or AWS SES for email sending  
**Estimated Time**: 2-3 hours  
**Priority**: HIGH

### Medium Priority Actions (P2)

#### 6. Add HTTPS/TLS Configuration
**Current State**: HTTP only  
**Risk**: Credentials transmitted in plaintext  
**Action**: Configure TLS certificates, enforce HTTPS  
**Estimated Time**: 2-3 hours  
**Priority**: MEDIUM

#### 7. Implement Token Cleanup Job
**Current State**: Expired tokens accumulate in database  
**Risk**: Database bloat  
**Action**: Scheduled job to delete expired tokens  
**Estimated Time**: 1-2 hours  
**Priority**: MEDIUM

### Documentation Updates Needed

1. Update API documentation with actual endpoints
2. Document mobile-backend integration steps
3. Create deployment guide with security checklist
4. Document environment variables and configuration

---

## Implementation Checklist

### Backend ✅
- [x] Auth handlers (all endpoints)
- [x] Auth usecase (business logic)
- [x] JWT generation and validation
- [x] Refresh token rotation
- [x] Password recovery flow
- [x] Rate limiting middleware
- [x] Input sanitization middleware
- [x] Audit logging
- [x] Role-based access control
- [x] Database repositories
- [x] Unit tests (35% coverage)
- [ ] Integration tests
- [ ] Email integration
- [ ] HTTPS/TLS configuration

### Mobile ⚠️
- [x] UI screens (login, register, recovery)
- [x] Input validation
- [x] Loading states
- [ ] Secure token storage (flutter_secure_storage)
- [ ] Backend integration (disable dev mode)
- [ ] Remove hardcoded credentials
- [ ] Error handling
- [ ] Offline support
- [ ] Unit tests (50% coverage)
- [ ] Integration tests

### Integration ❌
- [ ] Mobile-backend connection
- [ ] End-to-end testing
- [ ] Error handling
- [ ] Network timeout handling
- [ ] Retry logic

---

**Document Updated**: Based on actual implementation analysis (6 de Abril, 2026)  
**Backend Status**: 100% implemented (Gin + MariaDB)  
**Mobile Status**: 70% implemented (needs secure storage + backend integration)  
**Next Review**: After completing P0 critical actions
