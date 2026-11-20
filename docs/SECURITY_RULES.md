# Security Rules — Lubricentros SaaS

> **Scope**: Backend (Go/Gin + MariaDB), Mobile (Flutter/Provider)
> **Status**: v1.0 — Production-ready baseline
> **Last updated**: 2026-04-03

---

## Table of Contents

1. [Authentication Rules](#1-authentication-rules)
2. [Authorization Rules](#2-authorization-rules)
3. [Data Security Rules](#3-data-security-rules)
4. [Infrastructure Security Rules](#4-infrastructure-security-rules)
5. [Missing Functionality Audit](#5-missing-functionality-audit)
6. [Implementation Priority Matrix](#6-implementation-priority-matrix)
7. [API Contract Summary](#7-api-contract-summary)
8. [Development Workflow](#8-development-workflow)
9. [Testing Strategy](#9-testing-strategy)

---

## 1. Authentication Rules

### 1.1 Password Requirements

| Rule | Value |
|------|-------|
| Minimum length | 8 characters |
| Maximum length | 128 characters (prevents DoS via hashing) |
| Must contain | Uppercase, lowercase, digit, special character |
| Banned patterns | Common passwords (check against HaveIBeenPwned API or local dictionary of top 10k) |
| Hashing algorithm | bcrypt |
| Bcrypt cost | 12 (production), 4 (testing only) |
| Storage | `password_hash` column only — NEVER plaintext |

**Validation regex** (backend, Go):
```go
var passwordRegex = regexp.MustCompile(`^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,128}$`)
```

### 1.2 JWT Token Lifecycle

| Token Type | Expiry | Storage | Rotation |
|------------|--------|---------|----------|
| Access Token | 15 minutes | Memory (Flutter) | N/A — short-lived |
| Refresh Token | 7 days | `refresh_tokens` table (SHA-256 hashed) | Yes — single-use rotation |

**Access Token claims**:
```json
{
  "sub": 1,
  "email": "user@example.com",
  "role": "customer",
  "iat": 1712102400,
  "exp": 1712103300
}
```

**Refresh Token flow**:
1. Client sends refresh token to `POST /api/v1/auth/refresh`
2. Server hashes incoming token (SHA-256), looks up in `refresh_tokens`
3. Validates: not expired, not revoked, user still active
4. Revokes old token, issues new access + refresh pair
5. Returns new pair — old refresh token is permanently invalid

**Security controls**:
- Refresh tokens stored as SHA-256 hashes (never plaintext in DB)
- `ip_address` and `user_agent` recorded at creation for anomaly detection
- `revoked_at` column for immediate invalidation on logout or compromise
- On password change: ALL refresh tokens for that user are revoked

### 1.3 Session Management

| Rule | Value |
|------|-------|
| Max concurrent sessions | 5 per user |
| Session enforcement | Count active (non-revoked, non-expired) refresh tokens |
| Forced logout | Admin can revoke all tokens; user can revoke all from profile |
| Idle timeout | Access token expires naturally (15 min) — no server-side session state |
| Concurrent login alert | Log when >3 active sessions detected (audit trail) |

### 1.4 Brute Force Protection

| Rule | Value |
|------|-------|
| Failed attempt threshold | 5 attempts |
| Lockout duration | 15 minutes |
| Tracking mechanism | In-memory map with TTL or Redis-backed counter (keyed by email + IP) |
| Reset counter | On successful login or after lockout expires |
| Response on lockout | `429 Too Many Requests` with `Retry-After` header |
| Audit log | Every failed attempt logged to `audit_log` table |

**Implementation note**: Use a sliding window counter, not a fixed window. A fixed window allows burst attacks at window boundaries.

### 1.5 Password Reset Flow

```
1. User requests reset → POST /api/v1/auth/forgot-password {email}
2. Server generates cryptographically random token (32 bytes, hex-encoded)
3. Token stored hashed (SHA-256) in DB with 1h expiry
4. Email sent with reset link: https://app/reset?token=XYZ
5. User submits new password → POST /api/v1/auth/reset-password {token, new_password}
6. Server validates: token exists, not expired, not used
7. Password hashed, stored; token marked as used (single-use)
8. ALL existing refresh tokens revoked (forced re-login)
```

| Rule | Value |
|------|-------|
| Token expiry | 1 hour |
| Single use | Yes — token invalidated after first use |
| Token format | 64-char hex (32 bytes from `crypto/rand`) |
| Rate limit | 3 requests per email per hour |
| Response | Always return `200` regardless of email existence (prevents enumeration) |

---

## 2. Authorization Rules

### 2.1 RBAC Matrix

| Resource | Customer | Admin |
|----------|----------|-------|
| Own vehicles (CRUD) | Own only | All |
| Own appointments (CRUD) | Own only | All |
| Own service history (Read) | Own vehicles only | All |
| Vehicle reports (Read) | Own vehicles only | All |
| Appointment status update | Read only | Read/Write |
| Service record creation | No | Yes |
| Product inventory (CRUD) | No | Yes |
| User management | Own profile only | All users |
| Ownership transfers | Initiate for own vehicles | Approve/Reject all |
| Audit log access | No | Read only |
| Attachments upload | Own entities only | All entities |

### 2.2 Resource Ownership Checks

**Every** handler that accesses a resource MUST verify ownership:

```go
// Correct: ownership check before access
func (h *VehicleHandler) GetVehicle(w http.ResponseWriter, r *http.Request) {
    userID := middleware.GetUserID(r.Context())
    vehicleID := mux.Vars(r)["id"]

    vehicle, err := h.service.GetVehicleByID(r.Context(), userID, vehicleID)
    if err != nil {
        if errors.Is(err, domain.ErrNotFound) {
            response.NotFound(w, "Vehicle not found")
            return
        }
        response.InternalError(w)
        return
    }
    // ...
}
```

```go
// Repository enforces ownership at query level
func (r *VehicleRepository) GetVehicleByID(ctx context.Context, userID uint, vehicleID uint) (*entity.Vehicle, error) {
    query := "SELECT id, user_id, patente, marca, modelo, anio, motor, km_actual, color, created_at, updated_at FROM vehicles WHERE id = ? AND user_id = ?"
    // ...
}
```

**Rule**: Never trust client-supplied `user_id` in request body. Always derive from JWT claims.

### 2.3 Admin Override Rules

- Admins can access any resource BUT their actions are logged to `audit_log`
- Admins cannot bypass ownership checks silently — the query includes `user_id` filter unless the role is `admin`
- Admin-only endpoints: `PATCH /appointments/:id/status`, `POST /services`, `POST /products`, `GET /admin/*`

### 2.4 API Endpoint Protection Levels

| Level | Description | Endpoints |
|-------|-------------|-----------|
| **Public** | No auth required | `POST /auth/register`, `POST /auth/login`, `POST /auth/forgot-password`, `POST /auth/reset-password`, `GET /health` |
| **Authenticated** | Valid JWT required | All `GET /vehicles`, `POST /vehicles`, `GET /appointments`, `POST /appointments`, `GET /vehicles/:id/services` |
| **Admin** | Valid JWT + `role=admin` | `PATCH /appointments/:id/status`, `POST /services`, CRUD `/products`, `GET /admin/*` |
| **Owner** | Valid JWT + resource ownership | `GET /vehicles/:id`, `PUT /vehicles/:id`, `DELETE /vehicles/:id`, `GET /vehicles/:id/report` |

---

## 3. Data Security Rules

### 3.1 Password Hashing

- Algorithm: **bcrypt** with cost factor **12**
- Library: `golang.org/x/crypto/bcrypt`
- Cost factor configurable via env var `BCRYPT_COST` (default: 12, min: 10)
- Testing cost: 4 (speed up tests, never ship with cost < 10)

### 3.2 Sensitive Data at Rest

| Field | Encryption | Method |
|-------|-----------|--------|
| `password_hash` | bcrypt (one-way) | Built-in |
| `refresh_tokens.token_hash` | SHA-256 (one-way) | `crypto/sha256` |
| `users.phone` | No (PII, consider AES-256-GCM for compliance) | — |
| `users.email` | No (used as identifier) | — |
| `audit_log.ip_address` | No (operational data) | — |

**Recommendation**: If GDPR or local data protection laws apply, encrypt `phone` at rest using AES-256-GCM with a key managed via environment variable or secrets manager.

### 3.3 File Upload Security

| Rule | Value |
|------|-------|
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp`, `application/pdf` |
| Max file size | 5 MB per file |
| Max files per request | 3 |
| Storage path | `/uploads/{entity_type}/{entity_id}/{uuid}.{ext}` |
| Filename | UUID-generated — NEVER use client-supplied filename |
| Path sanitization | Strip all path components, validate against directory traversal |
| Virus scanning | Recommended: ClamAV integration for production |
| Access control | Files served through authenticated endpoint, NOT direct filesystem access |

```go
// Path sanitization example
func sanitizeFilename(original string) string {
    // Strip directory components
    base := filepath.Base(original)
    // Only allow alphanumeric, dots, hyphens, underscores
    return regexp.MustCompile(`[^a-zA-Z0-9._-]`).ReplaceAllString(base, "")
}
```

### 3.4 SQL Injection Prevention

- **ALL** queries MUST use parameterized queries (`?` placeholders with `database/sql`)
- NO string concatenation or `fmt.Sprintf` for SQL queries
- Repository layer is the ONLY place SQL is constructed
- Use `go-playground/validator` for input validation before reaching repository

```go
// Correct: parameterized query
query := "SELECT * FROM vehicles WHERE id = ? AND user_id = ?"
row := db.QueryRowContext(ctx, query, vehicleID, userID)

// NEVER: string concatenation
query := fmt.Sprintf("SELECT * FROM vehicles WHERE id = %s", vehicleID)
```

### 3.5 XSS Prevention

- Backend: All JSON responses use `json.Marshal` (auto-escapes HTML entities)
- Frontend (Flutter): Use `Text` widget by default — NEVER `Html` widget with untrusted content
- Input sanitization: Strip HTML tags from `observaciones`, `reason`, `notes` fields
- Content-Type headers: Always set `Content-Type: application/json` on API responses

### 3.6 CORS Policy

| Environment | Allowed Origins |
|-------------|----------------|
| Development | `http://localhost:*`, `http://127.0.0.1:*` |
| Staging | `https://staging.lubricentros.com` |
| Production | `https://app.lubricentros.com` |

```go
// Gin CORS configuration
config := cors.DefaultConfig()
config.AllowOrigins = strings.Split(os.Getenv("CORS_ALLOWED_ORIGINS"), ",")
config.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
config.AllowHeaders = []string{"Origin", "Content-Type", "Authorization", "X-Request-ID"}
config.AllowCredentials = true
config.MaxAge = 12 * time.Hour
router.Use(cors.New(config))
```

**Rules**:
- Never use `AllowAllOrigins` in production
- Explicitly list origins per environment via `CORS_ALLOWED_ORIGINS` env var
- Preflight cache: 12 hours

---

## 4. Infrastructure Security Rules

### 4.1 Rate Limiting

| Endpoint Group | Limit | Window |
|----------------|-------|--------|
| `/auth/*` | 10 req/min | Sliding window |
| `/auth/login` | 5 req/min | Sliding window |
| `/auth/forgot-password` | 3 req/hour | Fixed window |
| `/vehicles/*` | 60 req/min | Sliding window |
| `/appointments/*` | 30 req/min | Sliding window |
| `/services/*` | 30 req/min | Sliding window |
| All other | 120 req/min | Sliding window |

**Implementation**: Token bucket or sliding window counter. Store counters in-memory for single-instance; use Redis for multi-instance.

### 4.2 Request Size Limits

| Rule | Value |
|------|-------|
| Max JSON body size | 1 MB |
| Max URL length | 2048 characters |
| Max header size | 8 KB |
| Max multipart form size | 10 MB (for file uploads) |

```go
// Gin middleware to limit request body size
func MaxBodySize(maxBytes int64) gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
        c.Next()
    }
}
```

### 4.3 Timeout Policies

| Timeout | Value | Scope |
|---------|-------|-------|
| HTTP server read | 15 seconds | `http.Server.ReadTimeout` |
| HTTP server write | 15 seconds | `http.Server.WriteTimeout` |
| HTTP server idle | 60 seconds | `http.Server.IdleTimeout` |
| Database query | 10 seconds | `context.WithTimeout` per query |
| Database connection | 5 seconds | `sql.DB.SetConnMaxLifetime` |

### 4.4 Logging Rules

#### What TO Log
- Request method, path, status code, duration
- User ID (from JWT) on authenticated requests
- IP address (for audit trail)
- Resource IDs involved in operations
- Authentication events (login success/failure, token refresh, logout)
- Authorization failures (403 responses)
- Database errors (without query parameters)
- File upload events (filename, size, entity)

#### What NEVER to Log
- Passwords (any form: plaintext, hash, partial)
- JWT tokens (access or refresh)
- Request bodies containing sensitive fields
- Database connection strings
- API keys or secrets
- Full stack traces in production responses

**Current state**: The project already has `LoggingMiddleware` with password redaction (`internal/middleware/logging.go`). This is good but needs extension to cover:
- JWT token redaction in `Authorization` headers
- Request ID propagation for distributed tracing
- Structured logging (JSON format) for production

### 4.5 Error Handling

**Production responses MUST NOT expose**:
- Stack traces
- Internal error details
- Database error messages
- File paths
- Internal service names

```go
// Correct: generic error response
func InternalError(w http.ResponseWriter) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusInternalServerError)
    json.NewEncoder(w).Encode(APIError{
        Code:    "INTERNAL_ERROR",
        Message: "An unexpected error occurred. Please try again later.",
    })
}

// Log the real error internally
log.Printf("ERROR: failed to query vehicles: %v", err)
```

**Error response format**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request body",
    "details": [
      { "field": "email", "message": "must be a valid email address" }
    ]
  }
}
```

---

## 5. Missing Functionality Audit

### 5.1 Backend Missing

| Feature | Status | Notes |
|---------|--------|-------|
| **API endpoints** | 0 implemented | Only `/health` exists. All entity endpoints are stubs. |
| **JWT auth middleware** | Missing | `pkg/jwt/` directory is empty. Need middleware for token validation. |
| **JWT refresh endpoint** | Missing | `refresh_tokens` table exists but no endpoint to use it. |
| **File upload handling** | Missing | `attachments` table exists, no upload/download endpoints. |
| **Password reset flow** | Missing | No forgot-password or reset-password endpoints. |
| **Email service** | Missing | No SMTP integration for password reset, appointment reminders. |
| **Input validation middleware** | Missing | `go-playground/validator` is in go.mod but not wired up. |
| **CORS middleware** | Missing | No CORS configuration in `main.go`. |
| **Rate limiting** | Missing | No rate limiter on any endpoint. |
| **Request size limiting** | Missing | No body size limits. |
| **PDF report generation** | Missing | Vehicle report endpoint defined in `docs/api.md` but not implemented. |
| **Background jobs** | Missing | No job scheduler for appointment reminders, report generation. |
| **API documentation** | Missing | No OpenAPI/Swagger spec. |
| **Health checks** | Partial | Basic `/health` exists. Need liveness (`/health/live`) and readiness (`/health/ready`). |
| **Metrics/monitoring** | Missing | No Prometheus metrics, no structured logging. |
| **Database migration runner** | Missing | SQL files exist in `migrations/` but no Go migration tool (goose, migrate). |
| **Database driver mismatch** | BUG | `internal/database/db.go` uses `github.com/lib/pq` (PostgreSQL) but schema is MariaDB. Should use `github.com/go-sql-driver/mysql`. |
| **Repository implementations** | Missing | `internal/domain/repository/` and `internal/infrastructure/repository/` are empty. |
| **Handler implementations** | Missing | `internal/handler/` is empty. |
| **DTO definitions** | Missing | `internal/dto/` is empty. |
| **Service layer** | Missing | No business logic layer between handlers and repositories. |
| **Graceful shutdown** | Missing | Server does not handle SIGTERM/SIGINT. |
| **Configuration management** | Missing | No structured config loading (env vars only via `os.Getenv`). |

### 5.2 Mobile Missing

| Feature | Status | Notes |
|---------|--------|-------|
| **Real API integration** | Mock only | `AuthService` has `_devMode = true` — all calls return mock data. |
| **Secure token storage** | Missing | `ApiClient` stores token in memory (`String? _token`). Needs `flutter_secure_storage`. |
| **Token persistence** | Missing | Token lost on app restart. No `SharedPreferences` or secure storage. |
| **Token refresh** | Missing | No automatic refresh when access token expires. |
| **Forgot password screen** | Missing | Only `login_screen.dart` and `register_screen.dart` exist. |
| **Service history screen** | Missing | No UI for viewing service records. |
| **Vehicle report screen** | Missing | No PDF viewer or report display. |
| **Transfer ownership screen** | Missing | No UI for ownership transfer flow. |
| **Calendar view for appointments** | Missing | No calendar widget. |
| **User profile/settings** | Missing | No profile screen, no settings screen. |
| **Image upload/capture** | Missing | No `image_picker` or `camera` integration. |
| **Push notifications** | Not started | Future consideration. |
| **Offline support** | Missing | No `sqflite` cache, no offline-first strategy. |
| **Error handling UI** | Partial | Basic error messages exist but no retry mechanism. |
| **Loading states** | Partial | `loading_provider.dart` exists but not used consistently. |
| **Hardcoded dev credentials** | SECURITY RISK | `auth_service.dart` line 86: hardcoded `Admin123` — must be removed before production. |

### 5.3 Database Missing

| Feature | Status | Notes |
|---------|--------|-------|
| **Migration runner** | Missing | SQL files exist but no automated runner. |
| **Seed data** | Missing | No seed scripts for development/testing. |
| **Backup automation** | Missing | `docs/database.md` mentions "backups diarios" but no implementation. |
| **Index optimization** | Partial | Basic indexes exist. Need composite indexes for common queries. |
| **Foreign key indexes** | Partial | Most FK columns are indexed. Verify `service_parts_used.product_id`. |
| **Database user permissions** | Missing | No GRANT statements — app likely runs as root. |
| **Connection pooling config** | Missing | No `SetMaxOpenConns`, `SetMaxIdleConns` configuration. |

---

## 6. Implementation Priority Matrix

### Phase 1 — Foundation (Week 1-2)

| Feature | Impact | Effort | Priority | Phase |
|---------|--------|--------|----------|-------|
| Fix DB driver (postgres → mysql) | CRITICAL | Low | P0 | 1 |
| Configuration management | CRITICAL | Low | P0 | 1 |
| DB connection with pooling | CRITICAL | Low | P0 | 1 |
| JWT middleware (validate + extract claims) | CRITICAL | Medium | P0 | 1 |
| Auth endpoints (register, login, refresh) | CRITICAL | Medium | P0 | 1 |
| Password validation middleware | CRITICAL | Low | P0 | 1 |
| Brute force protection | CRITICAL | Medium | P0 | 1 |
| Vehicle CRUD (with ownership checks) | CRITICAL | Low | P0 | 1 |
| Token secure storage (mobile) | CRITICAL | Low | P0 | 1 |
| Remove dev mode + hardcoded credentials | CRITICAL | Low | P0 | 1 |

### Phase 2 — Core Features (Week 3-4)

| Feature | Impact | Effort | Priority | Phase |
|---------|--------|--------|----------|-------|
| Appointment CRUD | HIGH | Medium | P1 | 2 |
| Service history (read for customer) | HIGH | Low | P1 | 2 |
| Service record creation (admin) | HIGH | Medium | P1 | 2 |
| Appointment status update (admin) | HIGH | Low | P1 | 2 |
| Vehicle report endpoint | HIGH | Medium | P1 | 2 |
| Forgot password + reset flow | HIGH | Medium | P1 | 2 |
| Email service (SMTP) | HIGH | Medium | P1 | 2 |
| Mobile: real API integration | HIGH | High | P1 | 2 |
| Mobile: service history screen | HIGH | Medium | P1 | 2 |
| Mobile: appointment screens | HIGH | Medium | P1 | 2 |

### Phase 3 — Advanced Features (Week 5-6)

| Feature | Impact | Effort | Priority | Phase |
|---------|--------|--------|----------|-------|
| File upload handling | MEDIUM | Medium | P2 | 3 |
| Product inventory CRUD (admin) | MEDIUM | Low | P2 | 3 |
| Ownership transfer flow | MEDIUM | Medium | P2 | 3 |
| PDF report generation | MEDIUM | High | P2 | 3 |
| Mobile: image upload/capture | MEDIUM | Medium | P2 | 3 |
| Mobile: vehicle report screen | MEDIUM | Medium | P2 | 3 |
| Mobile: transfer ownership screen | MEDIUM | Medium | P2 | 3 |
| Mobile: calendar view | MEDIUM | Medium | P2 | 3 |
| Offline support (sqflite cache) | HIGH | High | P2 | 3 |

### Phase 4 — Production Readiness (Week 7-8)

| Feature | Impact | Effort | Priority | Phase |
|---------|--------|--------|----------|-------|
| Migration runner (goose/migrate) | HIGH | Low | P3 | 4 |
| Seed data for development | MEDIUM | Low | P3 | 4 |
| Rate limiting middleware | HIGH | Medium | P3 | 4 |
| CORS configuration | HIGH | Low | P3 | 4 |
| Request size limiting | MEDIUM | Low | P3 | 4 |
| Graceful shutdown | MEDIUM | Low | P3 | 4 |
| Health checks (liveness + readiness) | MEDIUM | Low | P3 | 4 |
| Structured logging (JSON) | MEDIUM | Low | P3 | 4 |
| OpenAPI/Swagger documentation | MEDIUM | Medium | P3 | 4 |
| Backup automation | HIGH | Medium | P3 | 4 |
| Mobile: user profile/settings | MEDIUM | Medium | P3 | 4 |
| Mobile: push notifications | LOW | High | P3 | 4 |

---

## 7. API Contract Summary

### 7.1 Global Conventions

| Aspect | Rule |
|--------|------|
| Base path | `/api/v1` |
| Content-Type | `application/json` (all requests and responses) |
| Auth header | `Authorization: Bearer <access_token>` |
| Response envelope | `{ "data": {...}, "error": null }` or `{ "data": null, "error": {...} }` |
| Pagination | `?page=1&per_page=20` → `{ "data": [], "meta": { "page": 1, "per_page": 20, "total": 100 } }` |
| Date format | ISO 8601 UTC: `2026-04-15T10:00:00Z` |
| ID format | Unsigned integer (MariaDB AUTO_INCREMENT) |

### 7.2 Authentication Endpoints

**Base**: `/api/v1/auth`
**Auth required**: No (all public)
**Rate limit**: 10 req/min (5 req/min for `/login`)

| Method | Path | Description | Request | Response |
|--------|------|-------------|---------|----------|
| POST | `/register` | Create account | `{email, password, name, phone?}` | `{token, refresh_token, user}` |
| POST | `/login` | Authenticate | `{email, password}` | `{token, refresh_token, user}` |
| POST | `/refresh` | Refresh access token | `{refresh_token}` | `{token, refresh_token}` |
| POST | `/logout` | Revoke refresh token | `{refresh_token}` | `204 No Content` |
| POST | `/forgot-password` | Request reset | `{email}` | `200 OK` (always) |
| POST | `/reset-password` | Reset password | `{token, new_password}` | `200 OK` |
| POST | `/change-password` | Change (authenticated) | `{current_password, new_password}` | `200 OK` |

**Error codes**: `400` (validation), `401` (invalid credentials), `409` (email exists), `429` (rate limited)

### 7.3 Vehicle Endpoints

**Base**: `/api/v1/vehicles`
**Auth required**: Yes (JWT)
**Rate limit**: 60 req/min

| Method | Path | Description | Auth Level | Request | Response |
|--------|------|-------------|------------|---------|----------|
| GET | `/` | List user's vehicles | Owner | — | `{vehicles: [...]}` |
| POST | `/` | Create vehicle | Authenticated | `{marca, modelo, anio, motor?, patente?, color?}` | `{vehicle}` |
| GET | `/:id` | Get vehicle detail | Owner | — | `{vehicle}` |
| PUT | `/:id` | Update vehicle | Owner | `{marca?, modelo?, anio?, motor?, km_actual?, patente?, color?}` | `{vehicle}` |
| DELETE | `/:id` | Delete vehicle | Owner | — | `204 No Content` |
| GET | `/:id/services` | Service history | Owner | `?page=&per_page=` | `{services: [...], meta}` |
| GET | `/:id/report` | Full vehicle report | Owner | — | `{vehicle, status, ultimo_service, proximo_service_km, services_count, historial}` |
| GET | `/:id/attachments` | List attachments | Owner | — | `{attachments: [...]}` |
| POST | `/:id/attachments` | Upload attachment | Owner | multipart/form-data | `{attachment}` |

**Error codes**: `400` (validation), `401` (unauthorized), `403` (not owner), `404` (not found)

### 7.4 Appointment Endpoints

**Base**: `/api/v1/appointments`
**Auth required**: Yes (JWT)
**Rate limit**: 30 req/min

| Method | Path | Description | Auth Level | Request | Response |
|--------|------|-------------|------------|---------|----------|
| GET | `/` | List user's appointments | Owner | `?status=&from=&to=` | `{appointments: [...], meta}` |
| POST | `/` | Create appointment | Authenticated | `{vehicle_id, fecha, tipo_service, observaciones?}` | `{appointment}` |
| GET | `/:id` | Get appointment detail | Owner | — | `{appointment}` |
| PATCH | `/:id/status` | Update status | Admin | `{status}` | `{appointment}` |
| DELETE | `/:id` | Cancel appointment | Owner | — | `204 No Content` |

**Error codes**: `400` (validation), `401` (unauthorized), `403` (not owner/admin), `404` (not found), `409` (time slot conflict)

### 7.5 Service Record Endpoints

**Base**: `/api/v1/services`
**Auth required**: Yes (JWT)
**Rate limit**: 30 req/min

| Method | Path | Description | Auth Level | Request | Response |
|--------|------|-------------|------------|---------|----------|
| GET | `/` | List services (admin: all, customer: own vehicles) | Authenticated | `?vehicle_id=&from=&to=` | `{services: [...], meta}` |
| POST | `/` | Create service record | Admin | `{vehicle_id, appointment_id?, fecha, km, tipo_aceite, marca_aceite?, costo_total?, observaciones?, parts_used?: [{product_id, cantidad, costo_unitario}]}` | `{service}` |
| GET | `/:id` | Get service detail | Authenticated | — | `{service, parts_used: [...]}` |
| POST | `/:id/addendum` | Add correction | Admin | `{field_name, old_value, new_value, reason}` | `{addendum}` |

**Error codes**: `400` (validation), `401` (unauthorized), `403` (admin only for write), `404` (not found)

### 7.6 Product Endpoints (Admin Only)

**Base**: `/api/v1/products`
**Auth required**: Yes (JWT + admin)
**Rate limit**: 60 req/min

| Method | Path | Description | Auth Level | Request | Response |
|--------|------|-------------|------------|---------|----------|
| GET | `/` | List products | Admin | `?categoria=&is_active=` | `{products: [...], meta}` |
| POST | `/` | Create product | Admin | `{sku, nombre, categoria, descripcion?, precio, stock_actual?, stock_minimo?}` | `{product}` |
| GET | `/:id` | Get product detail | Admin | — | `{product}` |
| PUT | `/:id` | Update product | Admin | `{nombre?, descripcion?, precio?, stock_actual?, stock_minimo?, is_active?}` | `{product}` |
| DELETE | `/:id` | Deactivate product | Admin | — | `204 No Content` |

### 7.7 Ownership Transfer Endpoints

**Base**: `/api/v1/vehicles/:id/transfers`
**Auth required**: Yes (JWT)
**Rate limit**: 10 req/min

| Method | Path | Description | Auth Level | Request | Response |
|--------|------|-------------|------------|---------|----------|
| POST | `/` | Request transfer | Owner | `{to_user_email, reason?}` | `{transfer}` |
| GET | `/` | List transfers for vehicle | Owner/Admin | — | `{transfers: [...]}` |
| PATCH | `/:transfer_id` | Approve/reject | Admin | `{status: "completed" \| "rejected", notes?}` | `{transfer}` |

### 7.8 Global Error Response Format

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "details": []
  }
}
```

**Standard error codes**:

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Request body failed validation |
| `UNAUTHORIZED` | 401 | Missing or invalid JWT |
| `TOKEN_EXPIRED` | 401 | Access token has expired |
| `TOKEN_REVOKED` | 401 | Refresh token was revoked |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource does not exist |
| `CONFLICT` | 409 | Resource conflict (e.g., duplicate email, slot overlap) |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

---

## 8. Development Workflow

### 8.1 Running Backend Locally

```bash
# 1. Start MariaDB (Docker)
docker run -d --name mariadb-dev \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=lubricentros \
  -e MYSQL_USER=lubricentros \
  -e MYSQL_PASSWORD=lubricentros \
  -p 3306:3306 \
  mariadb:10.6

# 2. Run migrations
mysql -u lubricentros -plubricentros -h 127.0.0.1 lubricentros < backend/migrations/001_mariadb_schema.sql

# 3. Set environment variables
export DB_HOST=127.0.0.1
export DB_PORT=3306
export DB_USER=lubricentros
export DB_PASSWORD=lubricentros
export DB_NAME=lubricentros
export JWT_SECRET=dev-secret-change-in-production
export BCRYPT_COST=4

# 4. Run server
cd backend
go run cmd/api/main.go
```

### 8.2 Running Mobile Locally

```bash
cd mobile
flutter pub get
flutter run -d chrome  # or -d <device-id>
```

### 8.3 Testing API Endpoints (curl)

```bash
# Register
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!","name":"Test User"}'

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'

# Create vehicle (with token)
curl -X POST http://localhost:8080/api/v1/vehicles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"marca":"Toyota","modelo":"Corolla","anio":2020,"km_actual":45000}'

# List vehicles
curl -X GET http://localhost:8080/api/v1/vehicles \
  -H "Authorization: Bearer <token>"
```

### 8.4 Adding New Endpoints

1. Define entity in `internal/domain/entity/` (if new)
2. Define repository interface in `internal/domain/repository/`
3. Implement repository in `internal/infrastructure/repository/`
4. Define DTOs in `internal/dto/`
5. Create handler in `internal/handler/`
6. Register route in `cmd/api/main.go` (migrating to Gin router)
7. Add middleware chain (auth, rate limit, logging)
8. Write unit + integration tests
9. Update `docs/api.md` and OpenAPI spec

### 8.5 Git Workflow

| Convention | Format | Example |
|------------|--------|---------|
| Branch naming | `feature/<description>`, `fix/<description>`, `chore/<description>` | `feature/auth-endpoints` |
| Commit messages | Conventional Commits | `feat(auth): add login and register endpoints` |
| PR titles | Same as commit messages | `feat: implement vehicle CRUD with ownership checks` |

**Conventional Commit types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code restructuring (no behavior change)
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

---

## 9. Testing Strategy

### 9.1 Unit Tests

| What to Test | Location | Coverage Target |
|-------------|----------|-----------------|
| Password hashing/verification | `pkg/hash/` | 100% |
| JWT token generation/validation | `pkg/jwt/` | 100% |
| Input validation (DTOs) | `internal/dto/` | 90% |
| Business logic (service layer) | `internal/service/` | 85% |
| Entity methods (validation, calculations) | `internal/domain/entity/` | 90% |
| Password redaction in logging | `internal/middleware/` | 100% |
| Ownership check logic | Repository layer | 90% |

**Key test scenarios**:
- Password with edge cases (unicode, max length, special chars)
- JWT with expired, malformed, and revoked tokens
- Ownership: user A cannot access user B's resources
- Brute force: lockout after 5 failures, reset after cooldown
- Validation: all required fields, boundary values, invalid formats

### 9.2 Integration Tests

| What to Test | Scope |
|-------------|-------|
| Full auth flow (register → login → refresh → logout) | DB + HTTP |
| Vehicle CRUD with ownership isolation | DB + HTTP |
| Appointment creation with slot conflict detection | DB + HTTP |
| Service record creation with parts_used | DB + HTTP |
| File upload with type/size validation | DB + HTTP + filesystem |
| Password reset flow (token generation → expiry → single use) | DB + HTTP |

**Test database**: Use a dedicated test database, truncated between test suites. Use transactions with rollback for test isolation.

### 9.3 E2E Tests

| What to Test | Tool |
|-------------|------|
| Mobile: register → login → add vehicle → book appointment | `flutter_driver` / `integration_test` |
| Mobile: offline behavior (cached data display) | `integration_test` |
| Mobile: token expiry → auto-refresh → seamless UX | `integration_test` |
| API: concurrent requests → rate limiting behavior | `k6` / custom Go test |

### 9.4 Test Data Management

- **Seed data**: SQL scripts in `backend/migrations/seeds/` for development
- **Test fixtures**: Go structs in `internal/testutil/fixtures/`
- **Factory functions**: Helper functions to create test entities with random data
- **Cleanup**: Transaction rollback after each test (never commit in tests)

### 9.5 Mock Strategies

| Layer | Strategy | Tool |
|-------|----------|------|
| Database | Interface-based mocks | `sqlmock` |
| HTTP client | Mock server | `httptest` |
| Email service | Interface-based mock | Custom mock |
| File storage | In-memory filesystem | `afero` mock |
| External APIs | Mock server | `httptest.NewServer` |
| Mobile: API | Mock HTTP responses | `mockito` / manual mocks |

**Rule**: Never mock the layer you're testing. Mock only dependencies.

---

## Appendix A: Security Checklist (Pre-Production)

- [ ] All passwords hashed with bcrypt cost >= 12
- [ ] JWT secret is cryptographically random (32+ bytes)
- [ ] Refresh tokens stored as SHA-256 hashes
- [ ] Brute force protection active on all auth endpoints
- [ ] Rate limiting configured per endpoint group
- [ ] CORS restricted to production domains
- [ ] Request body size limits enforced
- [ ] All queries use parameterized statements
- [ ] No passwords, tokens, or secrets in logs
- [ ] Error responses are generic (no stack traces)
- [ ] File uploads validated (type, size, path)
- [ ] Dev mode disabled (`_devMode = false`)
- [ ] Hardcoded credentials removed
- [ ] HTTPS enforced (reverse proxy or TLS)
- [ ] Database user has minimal privileges (no DROP, no GRANT)
- [ ] Backup automation configured
- [ ] Audit log captures all write operations
- [ ] Graceful shutdown implemented
- [ ] Health checks configured for orchestrator

## Appendix B: Critical Security Findings (Current State)

1. **Database driver mismatch** — `internal/database/db.go` imports `github.com/lib/pq` (PostgreSQL) but the schema is MariaDB. Must switch to `github.com/go-sql-driver/mysql`.

2. **Hardcoded dev credentials** — `mobile/lib/services/auth_service.dart` line 86 contains `Admin123` as a hardcoded password. This is a CRITICAL security risk if shipped.

3. **No JWT implementation** — `pkg/jwt/` directory is empty despite `golang-jwt/jwt/v5` being in `go.mod`. No auth middleware exists.

4. **No input validation** — `go-playground/validator` is imported but not used anywhere. All request bodies are unvalidated.

5. **In-memory token storage** — Mobile app stores JWT in a plain `String?` variable. Token is lost on app restart and is not encrypted in memory.

6. **No HTTPS** — API client uses `http://localhost:8080`. Production must enforce HTTPS.

7. **No CSRF protection** — Not critical for mobile (no browser cookies), but relevant if a web admin panel is added later.
