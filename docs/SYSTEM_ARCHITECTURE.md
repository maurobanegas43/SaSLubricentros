# System Architecture — SaaS Lubricentros

**Version:** 1.0.0  
**Date:** 2026-04-03  
**Status:** Design Specification  

---

## Table of Contents

1. [High-Level Architecture Diagram](#1-high-level-architecture-diagram)
2. [Component Interaction Diagrams](#2-component-interaction-diagrams)
3. [API Contract Specifications](#3-api-contract-specifications)
4. [Authentication & Authorization Contract](#4-authentication--authorization-contract)
5. [Error Response Contract](#5-error-response-contract)
6. [File Upload Contract](#6-file-upload-contract)
7. [Report Generation Contract](#7-report-generation-contract)
8. [Cross-Cutting Concerns](#8-cross-cutting-concerns)
9. [Scalability Considerations](#9-scalability-considerations)
10. [Deployment Architecture](#10-deployment-architecture)

---

## 1. High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          MOBILE APP (Flutter)                           │
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │   Screens    │  │   Providers  │  │   Services   │  │   Models    │ │
│  │              │  │  (Provider)  │  │              │  │             │ │
│  │ LoginScreen  │──│ AuthProvider │──│ AuthService  │──│ User        │ │
│  │ VehiclesList │──│VehicleProvider│─│VehicleService│──│ Vehicle     │ │
│  │ ApptList     │──│ApptProvider  │──│ApptService   │──│ Appointment │ │
│  │ VehicleDetail│  │              │  │ ApiClient    │  │ ServiceRec  │ │
│  │ CreateAppt   │  │              │  │ StorageSvc   │  │ Report      │ │
│  └──────────────┘  └──────────────┘  └──────┬───────┘  └─────────────┘ │
│                                              │                          │
│  ┌───────────────────────────────────────────┴──────────────────────┐  │
│  │                    LOCAL STORAGE LAYER                            │  │
│  │  ┌──────────────────┐              ┌──────────────────────────┐  │  │
│  │  │  flutter_secure_ │              │   SQLite (sqflite)       │  │  │
│  │  │  storage         │              │   - Cached vehicles      │  │  │
│  │  │  - JWT token     │              │   - Cached appointments  │  │  │
│  │  │  - Refresh token │              │   - Offline service recs │  │  │
│  │  └──────────────────┘              │   - Pending mutations    │  │  │
│  │                                    └──────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
         │
         │ HTTPS / REST (JSON)
         │ Headers: Authorization: Bearer <JWT>
         │          X-Request-ID: <uuid>
         │          X-Client-Version: 1.0.0
         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY / BACKEND (Go)                      │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                     HTTP ROUTER (gorilla/mux)                     │ │
│  │                                                                   │ │
│  │  Route: /api/v1/auth/*        → Auth Handlers                     │ │
│  │  Route: /api/v1/vehicles/*    → Vehicle Handlers                  │ │
│  │  Route: /api/v1/appointments/*→ Appointment Handlers              │ │
│  │  Route: /api/v1/services/*    → Service Handlers                  │ │
│  │  Route: /api/v1/reports/*     → Report Handlers                   │ │
│  │  Route: /api/v1/uploads/*     → Upload Handlers                   │ │
│  │  Route: /health               → Health Check                      │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    MIDDLEWARE CHAIN                               │ │
│  │                                                                  │ │
│  │  1. RequestID     → Generate/correlate X-Request-ID              │ │
│  │  2. CORS          → Cross-origin policy                          │ │
│  │  3. RateLimiter   → Token bucket per IP/endpoint                 │ │
│  │  4. Logging       → Structured log + password redaction          │ │
│  │  5. Auth          → JWT validation (skip: /auth/*, /health)      │ │
│  │  6. Recovery      → Panic recovery → 500                         │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    HANDLER LAYER                                  │ │
│  │                                                                  │ │
│  │  auth_handler.go       → register, login, refresh, logout        │ │
│  │  vehicle_handler.go    → CRUD, transfer, report                  │ │
│  │  appointment_handler.go→ CRUD, status, available slots           │ │
│  │  service_handler.go    → create, list by vehicle                 │ │
│  │  upload_handler.go     → multipart image upload                  │ │
│  │  report_handler.go     → PDF generation, JSON report             │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    SERVICE / BUSINESS LOGIC                       │ │
│  │                                                                  │ │
│  │  auth_service.go       → bcrypt, JWT sign/verify                 │ │
│  │  vehicle_service.go    → ownership, validation, status calc      │ │
│  │  appointment_service.go→ overlap detection, slot availability    │ │
│  │  service_service.go    → next_km calculation, status derivation  │ │
│  │  report_service.go     → aggregate data, PDF generation          │ │
│  │  upload_service.go     → file validation, storage path           │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    REPOSITORY / DATA ACCESS                       │ │
│  │                                                                  │ │
│  │  user_repo.go          → queries on users table                  │ │
│  │  vehicle_repo.go       → queries on vehicles table               │ │
│  │  appointment_repo.go   → queries on appointments table           │ │
│  │  service_repo.go       → queries on services table               │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │                    FILE STORAGE (local → S3)                      │ │
│  │                                                                  │ │
│  │  Dev/Staging: ./uploads/{vehicle_id}/{filename}                  │ │
│  │  Production:  AWS S3 / MinIO  s3://lubricentros-uploads/...      │ │
│  └──────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
         │                              │
         │ TCP (lib/pq)                 │ Local FS / S3 SDK
         ▼                              ▼
┌─────────────────────┐      ┌─────────────────────────┐
│   PostgreSQL        │      │   File Storage          │
│                     │      │                         │
│  Tables:            │      │  Dev:  ./uploads/       │
│  - users            │      │  Prod: AWS S3 / MinIO   │
│  - vehicles         │      │                         │
│  - appointments     │      │  MIME whitelist:        │
│  - services         │      │  image/jpeg, png, webp  │
│                     │      │  application/pdf        │
│  Max conns: 25      │      └─────────────────────────┘
│  Idle conns: 5      │
│  Conn lifetime: 30m │
└─────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES (Future)                           │
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │  Email (SES) │  │  Push (FCM)  │  │  Payments    │                  │
│  │  - Welcome   │  │  - Reminder  │  │  - Mercado   │                  │
│  │  - Receipt   │  │  - Status    │  │    Pago      │                  │
│  │  - Report    │  │  - Promo     │  │  - Stripe    │                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Flow Summary

| Connection | Protocol | Direction | Auth |
|---|---|---|---|
| Flutter → Go Backend | HTTPS/REST JSON | Bidirectional | Bearer JWT |
| Go Backend → PostgreSQL | TCP (lib/pq) | Bidirectional | DB credentials |
| Go Backend → File Storage | Local FS / S3 SDK | Write | IAM / FS perms |
| Flutter SQLite → Flutter App | In-process | Read/Write | N/A |
| Flutter Secure Storage → Flutter App | In-process | Read/Write | OS keychain |

---

## 2. Component Interaction Diagrams

### 2.1 User Login Flow

```
User → LoginScreen: Enter credentials
LoginScreen → AuthProvider: login(email, password)
AuthProvider → AuthService: login()
AuthService → ApiClient: POST /api/v1/auth/login {email, password}
ApiClient → Go Backend: HTTPS POST with JSON body
Go Backend → DB: SELECT * FROM users WHERE email = ?
DB → Go Backend: User row (with password_hash)
Go Backend → Go Backend: bcrypt.CompareHashAndPassword
Go Backend → Go Backend: JWT.Sign(access, 24h) + JWT.Sign(refresh, 7d)
Go Backend → ApiClient: 200 {user, token, refresh_token, expires_in}
ApiClient → AuthService: AuthResult{success, token, user}
AuthService → AuthProvider: Update state
AuthProvider → StorageService: saveToken(token), saveRefreshToken(rt)
AuthProvider → LoginScreen: Navigate to /home
LoginScreen → User: HomeScreen displayed
```

### 2.2 Book Appointment Flow

```
User → CreateAppointmentScreen: Select vehicle + date + service type
CreateAppointmentScreen → ApptProvider: createAppointment(...)
ApptProvider → ApptService: createAppointment()
ApptService → ApiClient: POST /api/v1/appointments
ApiClient → Go Backend: POST {vehicle_id, fecha, tipo_service, observaciones}
Go Backend → Go Backend: JWT validate + extract user_id
Go Backend → DB: Check vehicle ownership (user_id = ?)
Go Backend → DB: Check overlap (COUNT WHERE vehicle_id + fecha + status != cancelled)
Go Backend → DB: INSERT INTO appointments (...)
Go Backend → ApiClient: 201 {appointment}
ApiClient → ApptService: Appointment created
ApptService → ApptProvider: Update state
ApptProvider → CreateAppointmentScreen: Show success + navigate back
CreateAppointmentScreen → User: Success toast
```

### 2.3 View Vehicle History Flow

```
User → VehicleDetailScreen: Tap vehicle card
VehicleDetailScreen → VehicleProvider: fetchVehicleHistory(vehicleId)
VehicleProvider → VehicleService: getServices(vehicleId)
VehicleService → ApiClient: GET /api/v1/vehicles/:id/services
ApiClient → Go Backend: GET + Authorization: Bearer <JWT>
Go Backend → Go Backend: JWT validate + extract user_id
Go Backend → DB: Check ownership (vehicles.user_id = ?)
Go Backend → DB: SELECT * FROM services WHERE vehicle_id = ? ORDER BY fecha DESC
DB → Go Backend: Service records
Go Backend → ApiClient: 200 {services: [...], pagination}
ApiClient → VehicleService: List<ServiceRecord>
VehicleService → VehicleProvider: Update state
VehicleProvider → VehicleDetailScreen: Render history list
VehicleDetailScreen → User: History displayed
```

### 2.4 Transfer Ownership Flow

```
User → VehicleDetailScreen: Tap "Transfer Ownership"
VehicleDetailScreen → User: Show transfer dialog (new owner email)
User → VehicleDetailScreen: Enter new owner email
VehicleDetailScreen → VehicleProvider: confirmTransfer(vehicleId, newOwnerEmail)
VehicleProvider → VehicleService: transferOwnership()
VehicleService → ApiClient: POST /api/v1/vehicles/:id/transfer {new_owner_email}
ApiClient → Go Backend: POST + Authorization: Bearer <JWT>
Go Backend → Go Backend: JWT validate + extract user_id
Go Backend → DB: Check current ownership
Go Backend → DB: SELECT id FROM users WHERE email = ? (new owner)
Go Backend → Go Backend: BEGIN TRANSACTION
Go Backend → DB: UPDATE vehicles SET user_id = new_owner_id WHERE id = ?
Go Backend → DB: INSERT INTO ownership_transfers (vehicle_id, previous_owner_id, new_owner_id)
Go Backend → Go Backend: COMMIT
Go Backend → ApiClient: 200 {message, transferred_at}
ApiClient → VehicleService: Success
VehicleService → VehicleProvider: Remove vehicle from local state
VehicleProvider → VehicleDetailScreen: Navigate back / update list
VehicleDetailScreen → User: Transfer confirmation toast
```

### 2.5 Generate Report Flow

```
User → VehicleDetailScreen: Tap "Generate Report"
VehicleDetailScreen → ReportService: generateReport(vehicleId, format)
ReportService → ApiClient: GET /api/v1/vehicles/:id/report?format=pdf
ApiClient → Go Backend: GET + Authorization: Bearer <JWT>
Go Backend → Go Backend: JWT validate + extract user_id
Go Backend → DB: Check ownership
Go Backend → DB: SELECT vehicle data
Go Backend → DB: SELECT services history (ORDER BY fecha DESC)
Go Backend → DB: SELECT ownership_transfers
Go Backend → Go Backend: Calculate status, next_service_km, averages
Go Backend → PDF Engine: Generate PDF (gofpdf)
PDF Engine → Go Backend: Binary PDF data
Go Backend → ApiClient: 200 Content-Type: application/pdf, Body: <binary>
ApiClient → ReportService: PDF bytes
ReportService → VehicleDetailScreen: Save to device + open share sheet
VehicleDetailScreen → User: PDF viewer / share dialog
```

---

## 3. API Contract Specifications

### Base Configuration

```
Base URL:    https://api.lubricentros.com/api/v1
Content-Type: application/json
Auth Header:  Authorization: Bearer <JWT>
Request ID:   X-Request-ID: <uuid-v4> (auto-generated if missing)
```

### 3.1 Authentication Endpoints

#### POST /api/v1/auth/register

Register a new user account.

```
Request:
  Content-Type: application/json
  Body:
  {
    "email": "juan@example.com",
    "password": "SecureP@ss123",
    "name": "Juan Perez",
    "phone": "+5491123456789"
  }

Response 201 Created:
  {
    "data": {
      "user": {
        "id": 1,
        "email": "juan@example.com",
        "name": "Juan Perez",
        "phone": "+5491123456789",
        "role": "user",
        "created_at": "2026-04-03T10:00:00Z"
      },
      "token": "eyJhbGciOiJIUzI1NiIs...",
      "refresh_token": "dGhpcyBpcyBhIHJlZnJl...",
      "expires_in": 86400
    }
  }

Response 409 Conflict:
  {
    "error": {
      "code": "email_already_exists",
      "message": "An account with this email already exists",
      "request_id": "req_abc123"
    }
  }

Response 422 Unprocessable Entity:
  {
    "error": {
      "code": "validation_failed",
      "message": "Request body contains invalid fields",
      "details": [
        { "field": "email", "message": "Invalid email format" },
        { "field": "password", "message": "Must be at least 8 characters with 1 uppercase, 1 number" }
      ],
      "request_id": "req_abc123"
    }
  }
```

**Validation Rules:**
- `email`: Valid email format, max 255 chars, unique
- `password`: Min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit
- `name`: Min 2 chars, max 100 chars, alphanumeric + spaces
- `phone`: Optional, valid phone format, max 50 chars

---

#### POST /api/v1/auth/login

Authenticate user and receive tokens.

```
Request:
  Content-Type: application/json
  Body:
  {
    "email": "juan@example.com",
    "password": "SecureP@ss123"
  }

Response 200 OK:
  {
    "data": {
      "user": {
        "id": 1,
        "email": "juan@example.com",
        "name": "Juan Perez",
        "phone": "+5491123456789",
        "role": "user"
      },
      "token": "eyJhbGciOiJIUzI1NiIs...",
      "refresh_token": "dGhpcyBpcyBhIHJlZnJl...",
      "expires_in": 86400
    }
  }

Response 401 Unauthorized:
  {
    "error": {
      "code": "invalid_credentials",
      "message": "Invalid email or password",
      "request_id": "req_abc123"
    }
  }

Response 429 Too Many Requests:
  {
    "error": {
      "code": "rate_limited",
      "message": "Too many login attempts. Try again in 5 minutes",
      "retry_after": 300,
      "request_id": "req_abc123"
    }
  }
```

**Rate Limiting:** 5 attempts per email per 5-minute window.

---

#### POST /api/v1/auth/refresh

Refresh an expired access token using a valid refresh token.

```
Request:
  Content-Type: application/json
  Body:
  {
    "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
  }

Response 200 OK:
  {
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIs...",
      "refresh_token": "bmV3IHJlZnJlc2ggdG9r...",
      "expires_in": 86400
    }
  }

Response 401 Unauthorized:
  {
    "error": {
      "code": "invalid_refresh_token",
      "message": "Refresh token is invalid or expired",
      "request_id": "req_abc123"
    }
  }

Response 403 Forbidden:
  {
    "error": {
      "code": "token_revoked",
      "message": "This refresh token has been revoked",
      "request_id": "req_abc123"
    }
  }
```

---

#### POST /api/v1/auth/logout

Invalidate the current session (revoke refresh token).

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: application/json
  Body:
  {
    "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
  }

Response 200 OK:
  {
    "data": {
      "message": "Logged out successfully"
    }
  }

Response 401 Unauthorized:
  {
    "error": {
      "code": "unauthorized",
      "message": "Authentication required",
      "request_id": "req_abc123"
    }
  }
```

---

### 3.2 Vehicle Endpoints

#### GET /api/v1/vehicles

List all vehicles owned by the authenticated user.

```
Request:
  Authorization: Bearer <JWT>
  Query Parameters:
    - page (optional, default: 1): Page number
    - per_page (optional, default: 20, max: 50): Items per page
    - search (optional): Search by marca, modelo, or patente

Response 200 OK:
  {
    "data": {
      "vehicles": [
        {
          "id": 1,
          "user_id": 1,
          "marca": "Toyota",
          "modelo": "Corolla",
          "anio": 2020,
          "motor": "1.8",
          "patente": "ABC123",
          "vin": "1HGBH41JXMN109186",
          "km_actual": 45000,
          "status": "ok",
          "ultimo_service": {
            "fecha": "2026-03-01T10:00:00Z",
            "km": 40000,
            "tipo_aceite": "sintetico"
          },
          "proximo_service_km": 50000,
          "created_at": "2026-01-15T08:00:00Z",
          "updated_at": "2026-03-01T10:00:00Z"
        }
      ],
      "pagination": {
        "page": 1,
        "per_page": 20,
        "total": 1,
        "total_pages": 1
      }
    }
  }

Response 401 Unauthorized:
  { "error": { "code": "unauthorized", "message": "Authentication required" } }
```

**Vehicle Status Calculation:**
- `ok`: km_actual < proximo_service_km - 500
- `maintenance_due`: km_actual >= proximo_service_km - 500 AND km_actual < proximo_service_km
- `critical`: km_actual >= proximo_service_km
- `unknown`: No service history yet

---

#### GET /api/v1/vehicles/:id

Get a single vehicle by ID.

```
Request:
  Authorization: Bearer <JWT>

Response 200 OK:
  {
    "data": {
      "vehicle": {
        "id": 1,
        "user_id": 1,
        "marca": "Toyota",
        "modelo": "Corolla",
        "anio": 2020,
        "motor": "1.8",
        "patente": "ABC123",
        "vin": "1HGBH41JXMN109186",
        "km_actual": 45000,
        "status": "ok",
        "ultimo_service": { ... },
        "proximo_service_km": 50000,
        "created_at": "2026-01-15T08:00:00Z",
        "updated_at": "2026-03-01T10:00:00Z"
      }
    }
  }

Response 404 Not Found:
  {
    "error": {
      "code": "vehicle_not_found",
      "message": "Vehicle with ID 1 not found",
      "request_id": "req_abc123"
    }
  }

Response 403 Forbidden:
  {
    "error": {
      "code": "forbidden",
      "message": "You do not own this vehicle",
      "request_id": "req_abc123"
    }
  }
```

---

#### POST /api/v1/vehicles

Create a new vehicle.

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: application/json
  Body:
  {
    "marca": "Toyota",
    "modelo": "Corolla",
    "anio": 2020,
    "motor": "1.8",
    "patente": "ABC123",
    "vin": "1HGBH41JXMN109186",
    "km_actual": 0
  }

Response 201 Created:
  {
    "data": {
      "vehicle": {
        "id": 1,
        "user_id": 1,
        "marca": "Toyota",
        "modelo": "Corolla",
        "anio": 2020,
        "motor": "1.8",
        "patente": "ABC123",
        "vin": "1HGBH41JXMN109186",
        "km_actual": 0,
        "status": "unknown",
        "created_at": "2026-04-03T10:00:00Z",
        "updated_at": "2026-04-03T10:00:00Z"
      }
    }
  }

Response 409 Conflict:
  {
    "error": {
      "code": "duplicate_patente",
      "message": "A vehicle with patente ABC123 already exists in your garage",
      "request_id": "req_abc123"
    }
  }
```

**Validation Rules:**
- `marca`: Required, 2-100 chars
- `modelo`: Required, 2-100 chars
- `anio`: Required, 1900-current year
- `motor`: Optional, max 100 chars
- `patente`: Optional, unique per user, max 20 chars
- `vin`: Optional, unique per user, max 17 chars (standard VIN)
- `km_actual`: Required, >= 0

---

#### PUT /api/v1/vehicles/:id

Update vehicle details (primarily km_actual).

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: application/json
  Body (all fields optional):
  {
    "km_actual": 46000,
    "motor": "2.0",
    "patente": "XYZ789"
  }

Response 200 OK:
  {
    "data": {
      "vehicle": { ... }
    }
  }

Response 422 Unprocessable Entity:
  {
    "error": {
      "code": "validation_failed",
      "message": "km_actual cannot be less than current value (45000)",
      "details": [
        { "field": "km_actual", "message": "Cannot decrease kilometers" }
      ],
      "request_id": "req_abc123"
    }
  }
```

---

#### DELETE /api/v1/vehicles/:id

Delete a vehicle (soft delete).

```
Request:
  Authorization: Bearer <JWT>

Response 200 OK:
  {
    "data": {
      "message": "Vehicle deleted successfully"
    }
  }

Response 404 Not Found:
  {
    "error": {
      "code": "vehicle_not_found",
      "message": "Vehicle with ID 1 not found",
      "request_id": "req_abc123"
    }
  }
```

**Note:** Soft delete sets `deleted_at` timestamp. Associated appointments are cancelled. Service history is preserved for audit.

---

#### POST /api/v1/vehicles/:id/transfer

Transfer vehicle ownership to another user.

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: application/json
  Body:
  {
    "new_owner_email": "newowner@example.com"
  }

Response 200 OK:
  {
    "data": {
      "message": "Vehicle ownership transferred successfully",
      "vehicle_id": 1,
      "previous_owner_id": 1,
      "new_owner_id": 2,
      "transferred_at": "2026-04-03T10:00:00Z"
    }
  }

Response 404 Not Found:
  {
    "error": {
      "code": "user_not_found",
      "message": "No account found with email newowner@example.com",
      "request_id": "req_abc123"
    }
  }

Response 409 Conflict:
  {
    "error": {
      "code": "self_transfer",
      "message": "Cannot transfer vehicle to yourself",
      "request_id": "req_abc123"
    }
  }
```

**Business Rules:**
- Only the current owner can initiate transfer
- New owner must have an existing account
- Service history is preserved (tied to vehicle, not owner)
- Transfer is logged in `ownership_transfers` table
- Cannot transfer if vehicle has pending appointments (must cancel first)

---

### 3.3 Appointment Endpoints

#### GET /api/v1/appointments

List appointments for the authenticated user.

```
Request:
  Authorization: Bearer <JWT>
  Query Parameters:
    - status (optional): pending | confirmed | completed | cancelled
    - vehicle_id (optional): Filter by vehicle
    - from (optional): ISO 8601 date, filter appointments from this date
    - to (optional): ISO 8601 date, filter appointments until this date
    - page (optional, default: 1)
    - per_page (optional, default: 20)

Response 200 OK:
  {
    "data": {
      "appointments": [
        {
          "id": 1,
          "user_id": 1,
          "vehicle_id": 1,
          "vehicle": {
            "marca": "Toyota",
            "modelo": "Corolla",
            "anio": 2020
          },
          "fecha": "2026-04-15T10:00:00Z",
          "tipo_service": "Cambio de aceite",
          "status": "confirmed",
          "observaciones": "Revisar frenos tambien",
          "created_at": "2026-04-03T10:00:00Z",
          "updated_at": "2026-04-03T10:00:00Z"
        }
      ],
      "pagination": {
        "page": 1,
        "per_page": 20,
        "total": 1,
        "total_pages": 1
      }
    }
  }
```

---

#### POST /api/v1/appointments

Create a new appointment.

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: application/json
  Body:
  {
    "vehicle_id": 1,
    "fecha": "2026-04-15T10:00:00Z",
    "tipo_service": "Cambio de aceite",
    "observaciones": "Revisar frenos tambien"
  }

Response 201 Created:
  {
    "data": {
      "appointment": { ... }
    }
  }

Response 409 Conflict:
  {
    "error": {
      "code": "appointment_overlap",
      "message": "You already have an appointment at this time for this vehicle",
      "request_id": "req_abc123"
    }
  }

Response 422 Unprocessable Entity:
  {
    "error": {
      "code": "validation_failed",
      "message": "Request body contains invalid fields",
      "details": [
        { "field": "fecha", "message": "Appointment date must be in the future" },
        { "field": "tipo_service", "message": "Must be one of: Cambio de aceite, Service completo, Cambio de filtros, Revision general, Otro" }
      ],
      "request_id": "req_abc123"
    }
  }
```

**Valid `tipo_service` values:**
- `Cambio de aceite`
- `Service completo`
- `Cambio de filtros`
- `Revision general`
- `Otro`

**Overlap Detection:**
```sql
SELECT COUNT(*) FROM appointments
WHERE vehicle_id = $1
  AND fecha = $2
  AND status NOT IN ('cancelled')
```

---

#### PATCH /api/v1/appointments/:id/status

Update appointment status (admin only, or user can cancel their own).

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: application/json
  Body:
  {
    "status": "confirmed"
  }

Response 200 OK:
  {
    "data": {
      "appointment": { ... }
    }
  }

Response 403 Forbidden:
  {
    "error": {
      "code": "forbidden",
      "message": "Only admins can confirm appointments. Users can only cancel their own.",
      "request_id": "req_abc123"
    }
  }

Response 422 Unprocessable Entity:
  {
    "error": {
      "code": "invalid_status_transition",
      "message": "Cannot transition from 'completed' to 'pending'",
      "details": [
        { "field": "status", "message": "Invalid status transition" }
      ],
      "request_id": "req_abc123"
    }
  }
```

**Valid Status Transitions:**
```
pending    → confirmed, cancelled
confirmed  → completed, cancelled
completed  → (terminal state)
cancelled  → (terminal state)
```

---

#### DELETE /api/v1/appointments/:id

Cancel an appointment (soft delete: status = cancelled).

```
Request:
  Authorization: Bearer <JWT>

Response 200 OK:
  {
    "data": {
      "message": "Appointment cancelled successfully",
      "appointment": { ... }
    }
  }

Response 403 Forbidden:
  {
    "error": {
      "code": "forbidden",
      "message": "Cannot cancel a completed appointment",
      "request_id": "req_abc123"
    }
  }
```

---

#### GET /api/v1/appointments/available-slots

Get available appointment slots for a given date range.

```
Request:
  Authorization: Bearer <JWT>
  Query Parameters:
    - date (required): YYYY-MM-DD
    - vehicle_id (optional): Check availability for specific vehicle

Response 200 OK:
  {
    "data": {
      "date": "2026-04-15",
      "slots": [
        { "time": "08:00", "available": true },
        { "time": "09:00", "available": true },
        { "time": "10:00", "available": false },
        { "time": "11:00", "available": true },
        { "time": "14:00", "available": true },
        { "time": "15:00", "available": true },
        { "time": "16:00", "available": true },
        { "time": "17:00", "available": false }
      ],
      "business_hours": {
        "start": "08:00",
        "end": "18:00",
        "slot_duration_minutes": 60
      }
    }
  }
```

**Business Hours (configurable via env):**
- Monday-Friday: 08:00-18:00
- Saturday: 08:00-13:00
- Sunday: Closed
- Slot duration: 60 minutes (configurable)

---

### 3.4 Service History Endpoints

#### GET /api/v1/vehicles/:id/services

Get service history for a vehicle.

```
Request:
  Authorization: Bearer <JWT>
  Query Parameters:
    - page (optional, default: 1)
    - per_page (optional, default: 20)
    - from (optional): ISO 8601 date
    - to (optional): ISO 8601 date

Response 200 OK:
  {
    "data": {
      "services": [
        {
          "id": 1,
          "vehicle_id": 1,
          "appointment_id": 1,
          "fecha": "2026-03-01T10:00:00Z",
          "km": 40000,
          "tipo_aceite": "sintetico",
          "marca_aceite": "Mobil 1",
          "productos": "Filtro de aceite, Filtro de aire",
          "observaciones": "Service completo realizado",
          "proximo_service_km": 50000,
          "technician": "Carlos Garcia",
          "images": [
            "https://storage.lubricentros.com/vehicles/1/services/1/before.jpg",
            "https://storage.lubricentros.com/vehicles/1/services/1/after.jpg"
          ],
          "created_at": "2026-03-01T10:00:00Z"
        }
      ],
      "pagination": {
        "page": 1,
        "per_page": 20,
        "total": 5,
        "total_pages": 1
      }
    }
  }

Response 403 Forbidden:
  {
    "error": {
      "code": "forbidden",
      "message": "You do not have access to this vehicle's history",
      "request_id": "req_abc123"
    }
  }
```

---

#### POST /api/v1/services

Register a completed service record (admin only).

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: application/json
  Body:
  {
    "vehicle_id": 1,
    "appointment_id": 1,
    "km": 45000,
    "tipo_aceite": "sintetico",
    "marca_aceite": "Mobil 1",
    "productos": "Filtro de aceite, Filtro de aire",
    "observaciones": "Service completo realizado",
    "technician": "Carlos Garcia"
  }

Response 201 Created:
  {
    "data": {
      "service": {
        "id": 2,
        "vehicle_id": 1,
        "appointment_id": 1,
        "fecha": "2026-04-03T10:00:00Z",
        "km": 45000,
        "tipo_aceite": "sintetico",
        "marca_aceite": "Mobil 1",
        "productos": "Filtro de aceite, Filtro de aire",
        "observaciones": "Service completo realizado",
        "proximo_service_km": 55000,
        "technician": "Carlos Garcia",
        "created_at": "2026-04-03T10:00:00Z"
      }
    }
  }

Response 403 Forbidden:
  {
    "error": {
      "code": "admin_only",
      "message": "Only administrators can register service records",
      "request_id": "req_abc123"
    }
  }

Response 409 Conflict:
  {
    "error": {
      "code": "duplicate_service",
      "message": "A service record already exists for this appointment",
      "request_id": "req_abc123"
    }
  }
```

**Next Service KM Calculation (auto):**
| Oil Type | Next Service KM |
|---|---|
| `mineral` | km + 5000 |
| `semi` | km + 7000 |
| `sintetico` | km + 10000 |

**Side Effects:**
- Updates vehicle's `km_actual` to the service km
- Updates vehicle's `updated_at`
- Updates associated appointment status to `completed`

---

### 3.5 Report Endpoints

#### GET /api/v1/vehicles/:id/report

Get a comprehensive vehicle report (JSON or PDF).

```
Request:
  Authorization: Bearer <JWT>
  Query Parameters:
    - format (optional): json | pdf (default: json)

Response 200 OK (JSON):
  {
    "data": {
      "report": {
        "generated_at": "2026-04-03T10:00:00Z",
        "vehicle": {
          "id": 1,
          "marca": "Toyota",
          "modelo": "Corolla",
          "anio": 2020,
          "motor": "1.8",
          "patente": "ABC123",
          "km_actual": 45000,
          "owner": "Juan Perez",
          "registered_at": "2026-01-15T08:00:00Z"
        },
        "status": "ok",
        "ultimo_service": {
          "fecha": "2026-03-01T10:00:00Z",
          "km": 40000,
          "tipo_aceite": "sintetico",
          "marca_aceite": "Mobil 1",
          "technician": "Carlos Garcia"
        },
        "proximo_service_km": 50000,
        "km_until_service": 5000,
        "services_count": 5,
        "total_km_covered": 45000,
        "average_service_interval_km": 9000,
        "oil_usage_summary": {
          "mineral": 1,
          "semi": 1,
          "sintetico": 3
        },
        "historial": [ ... ],
        "ownership_history": [ ... ]
      }
    }
  }

Response 200 OK (PDF):
  Content-Type: application/pdf
  Content-Disposition: attachment; filename="reporte-Toyota-Corolla-2026-04-03.pdf"
  Content-Length: 245760
  Body: <binary PDF data>
```

---

### 3.6 Upload Endpoints

#### POST /api/v1/uploads/vehicles/:id/images

Upload images for a vehicle or service record.

```
Request:
  Authorization: Bearer <JWT>
  Content-Type: multipart/form-data
  Body:
    - file: <binary image>
    - type (optional): vehicle | service (default: vehicle)
    - service_id (optional, required if type=service)

Response 201 Created:
  {
    "data": {
      "file": {
        "id": "img_abc123",
        "url": "https://storage.lubricentros.com/vehicles/1/images/photo_20260403_100000.jpg",
        "thumbnail_url": "https://storage.lubricentros.com/vehicles/1/images/thumbs/photo_20260403_100000.jpg",
        "filename": "photo_20260403_100000.jpg",
        "content_type": "image/jpeg",
        "size_bytes": 245760,
        "uploaded_at": "2026-04-03T10:00:00Z"
      }
    }
  }

Response 413 Payload Too Large:
  {
    "error": {
      "code": "file_too_large",
      "message": "File size exceeds maximum allowed (10MB)",
      "request_id": "req_abc123"
    }
  }

Response 415 Unsupported Media Type:
  {
    "error": {
      "code": "unsupported_file_type",
      "message": "File type 'image/gif' is not supported. Allowed: jpeg, png, webp",
      "request_id": "req_abc123"
    }
  }
```

---

## 4. Authentication & Authorization Contract

### 4.1 JWT Token Structure

**Access Token (short-lived):**
```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "sub": "1",                    // User ID
  "email": "juan@example.com",
  "role": "user",                // user | admin
  "iat": 1712138400,             // Issued at
  "exp": 1712224800,             // Expires at (+24h)
  "jti": "uuid-v4"               // Unique token ID (for revocation)
}

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  JWT_SECRET
)
```

**Refresh Token (long-lived):**
```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "sub": "1",
  "type": "refresh",             // Distinguishes from access token
  "iat": 1712138400,
  "exp": 1712743200,             // Expires at (+7d)
  "jti": "uuid-v4"               // Unique token ID (for revocation)
}
```

### 4.2 Token Configuration

```go
// config/auth.go
type AuthConfig struct {
    AccessTokenExpiry  time.Duration = 24 * time.Hour
    RefreshTokenExpiry time.Duration = 7 * 24 * time.Hour
    JWTSecret          string        // From env: JWT_SECRET
    JWTAlgorithm       string        = "HS256"
    Issuer             string        = "lubricentros-api"
}
```

### 4.3 Refresh Token Flow

```
1. Client sends request with expired access token
2. Server returns 401 with error code "token_expired"
3. Client sends POST /auth/refresh with refresh_token
4. Server validates refresh token:
   - Signature valid
   - Not expired
   - Not revoked (check against revocation store)
5. Server issues NEW access token + NEW refresh token (rotation)
6. Server revokes old refresh token
7. Client stores new tokens
```

**Token Rotation:** Every refresh invalidates the old refresh token and issues a new one. This limits the window of abuse if a refresh token is stolen.

### 4.4 Role-Based Access Control Matrix

```
┌──────────────────────────────────────┬──────┬───────┐
│ Endpoint                             │ user │ admin │
├──────────────────────────────────────┼──────┼───────┤
│ POST /auth/register                  │  YES │  YES  │
│ POST /auth/login                     │  YES │  YES  │
│ POST /auth/refresh                   │  YES │  YES  │
│ POST /auth/logout                    │  YES │  YES  │
│                                      │      │       │
│ GET    /vehicles                     │ own  │  all  │
│ GET    /vehicles/:id                 │ own  │  all  │
│ POST   /vehicles                     │  YES │  YES  │
│ PUT    /vehicles/:id                 │ own  │  all  │
│ DELETE /vehicles/:id                 │ own  │  all  │
│ POST   /vehicles/:id/transfer        │ own  │   -   │
│                                      │      │       │
│ GET    /appointments                 │ own  │  all  │
│ GET    /appointments/:id             │ own  │  all  │
│ POST   /appointments                 │  YES │  YES  │
│ PATCH  /appointments/:id/status      │cancel│  all  │
│ DELETE /appointments/:id             │ own  │  all  │
│ GET    /appointments/available-slots │  YES │  YES  │
│                                      │      │       │
│ GET    /vehicles/:id/services        │ own  │  all  │
│ POST   /services                     │   -  │  YES  │
│                                      │      │       │
│ GET    /vehicles/:id/report          │ own  │  all  │
│                                      │      │       │
│ POST   /uploads/vehicles/:id/images  │ own  │  all  │
└──────────────────────────────────────┴──────┴───────┘

Legend:
  YES   = Allowed (own resources for user, all for admin)
  own   = Only resources owned by the user
  all   = All resources in the system
  -     = Not allowed
  cancel= Users can only set status to "cancelled" on their own appointments
```

### 4.5 Session Invalidation Strategy

```
Storage: In-memory map (dev) → Redis (prod)
Key:     "revoked:<jti>" → expiry = token exp time

On logout:
  1. Parse refresh token to extract jti
  2. Add jti to revocation store with TTL = remaining token lifetime
  3. Return 200

On token validation:
  1. Verify signature
  2. Check expiry
  3. Check jti against revocation store
  4. If revoked → 403 token_revoked

On password change (future):
  1. Revoke ALL refresh tokens for user
  2. Force re-login on all devices
```

### 4.6 Token Expiry and Rotation Policy

| Token Type | Lifetime | Rotation | Revocable |
|---|---|---|---|
| Access Token | 24 hours | No (new on refresh) | Yes (via logout) |
| Refresh Token | 7 days | Yes (every use) | Yes (via logout) |

**Security Notes:**
- JWT secret must be min 256 bits, rotated quarterly
- Refresh token reuse detection: if a revoked refresh token is used, revoke ALL tokens for that user (indicates theft)
- No token persistence in server DB (stateless JWT + revocation list only)

---

## 5. Error Response Contract

### 5.1 Standard Error Format

```json
{
  "error": {
    "code": "resource_not_found",
    "message": "Vehicle with ID 42 not found",
    "details": {},
    "request_id": "req_abc123"
  }
}
```

### 5.2 Validation Error Format

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Request body contains invalid fields",
    "details": [
      { "field": "email", "message": "Invalid email format" },
      { "field": "password", "message": "Must be at least 8 characters" }
    ],
    "request_id": "req_abc123"
  }
}
```

### 5.3 Complete Error Code Registry

```
┌──────────────────────────────┬────────┬──────────────────────────────────────┐
│ Code                         │ HTTP   │ Description                          │
├──────────────────────────────┼────────┼──────────────────────────────────────┤
│ invalid_request              │ 400    │ Malformed request body               │
│ validation_failed            │ 422    │ Field validation errors              │
│ unauthorized                 │ 401    │ Missing or invalid auth              │
│ token_expired                │ 401    │ Access token has expired             │
│ invalid_credentials          │ 401    │ Wrong email/password                 │
│ invalid_refresh_token        │ 401    │ Refresh token invalid/expired        │
│ token_revoked                │ 403    │ Token was revoked (logout)           │
│ forbidden                    │ 403    │ Insufficient permissions             │
│ admin_only                   │ 403    │ Endpoint requires admin role         │
│ resource_not_found           │ 404    │ Generic resource not found           │
│ vehicle_not_found            │ 404    │ Vehicle ID not found                 │
│ appointment_not_found        │ 404    │ Appointment ID not found             │
│ user_not_found               │ 404    │ User not found                       │
│ email_already_exists         │ 409    │ Registration email duplicate         │
│ duplicate_patente            │ 409    │ Vehicle patente already exists       │
│ duplicate_service            │ 409    │ Service already exists for appt      │
│ appointment_overlap          │ 409    │ Time slot conflict                   │
│ self_transfer                │ 409    │ Cannot transfer to self              │
│ invalid_status_transition    │ 422    │ Invalid appointment status change    │
│ rate_limited                 │ 429    │ Too many requests                    │
│ file_too_large               │ 413    │ Upload exceeds size limit            │
│ unsupported_file_type        │ 415    │ MIME type not allowed                │
│ internal_error               │ 500    │ Unexpected server error              │
│ service_unavailable          │ 503    │ Database or dependency down          │
└──────────────────────────────┴────────┴──────────────────────────────────────┘
```

### 5.4 Go Error Helper

```go
// internal/api/errors.go
type APIError struct {
    Code      string      `json:"code"`
    Message   string      `json:"message"`
    Details   interface{} `json:"details,omitempty"`
    RequestID string      `json:"request_id"`
}

func (e APIError) StatusCode() int {
    switch e.Code {
    case "invalid_request":
        return http.StatusBadRequest
    case "validation_failed", "invalid_status_transition":
        return http.StatusUnprocessableEntity
    case "unauthorized", "token_expired", "invalid_credentials", "invalid_refresh_token":
        return http.StatusUnauthorized
    case "token_revoked", "forbidden", "admin_only":
        return http.StatusForbidden
    case "resource_not_found", "vehicle_not_found", "appointment_not_found", "user_not_found":
        return http.StatusNotFound
    case "email_already_exists", "duplicate_patente", "duplicate_service",
         "appointment_overlap", "self_transfer":
        return http.StatusConflict
    case "rate_limited":
        return http.StatusTooManyRequests
    case "file_too_large":
        return http.StatusRequestEntityTooLarge
    case "unsupported_file_type":
        return http.StatusUnsupportedMediaType
    default:
        return http.StatusInternalServerError
    }
}

func WriteError(w http.ResponseWriter, err APIError) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(err.StatusCode())
    json.NewEncoder(w).Encode(map[string]interface{}{
        "error": err,
    })
}
```

---

## 6. File Upload Contract

### 6.1 Multipart Form Structure

```
POST /api/v1/uploads/vehicles/:id/images
Authorization: Bearer <JWT>
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary...

------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="before.jpg"
Content-Type: image/jpeg

<binary data>
------WebKitFormBoundary
Content-Disposition: form-data; name="type"

service
------WebKitFormBoundary
Content-Disposition: form-data; name="service_id"

42
------WebKitFormBoundary--
```

### 6.2 File Type Whitelist

```go
var AllowedMIMETypes = map[string]bool{
    "image/jpeg": true,
    "image/png":  true,
    "image/webp": true,
    "application/pdf": true,
}

var AllowedExtensions = map[string]bool{
    ".jpg":  true,
    ".jpeg": true,
    ".png":  true,
    ".webp": true,
    ".pdf":  true,
}
```

### 6.3 Size Limits

| File Type | Max Size |
|---|---|
| Images (jpeg, png, webp) | 10 MB |
| PDF documents | 25 MB |

### 6.4 Storage Path Convention

```
Dev/Staging:
  ./uploads/
    vehicles/
      {vehicle_id}/
        images/
          {type}_{timestamp}_{uuid}.{ext}
        services/
          {service_id}/
            {type}_{timestamp}_{uuid}.{ext}

Production (S3):
  s3://lubricentros-uploads/
    vehicles/
      {vehicle_id}/
        images/
          {type}_{timestamp}_{uuid}.{ext}
        services/
          {service_id}/
            {type}_{timestamp}_{uuid}.{ext}
```

**Filename Generation:**
```go
func generateFilename(originalName string) string {
    ext := filepath.Ext(originalName) // ".jpg"
    ts := time.Now().UTC().Format("20060102_150405")
    uuid := uuid.New().String()[:8]
    return fmt.Sprintf("%s_%s.%s", ts, uuid, ext)
}
// Result: "20260403_100000_a1b2c3d4.jpg"
```

### 6.5 Response Format

```json
{
  "data": {
    "file": {
      "id": "img_a1b2c3d4",
      "url": "https://storage.lubricentros.com/vehicles/1/images/20260403_100000_a1b2c3d4.jpg",
      "thumbnail_url": "https://storage.lubricentros.com/vehicles/1/images/thumbs/20260403_100000_a1b2c3d4.jpg",
      "filename": "20260403_100000_a1b2c3d4.jpg",
      "original_filename": "before.jpg",
      "content_type": "image/jpeg",
      "size_bytes": 245760,
      "uploaded_at": "2026-04-03T10:00:00Z"
    }
  }
}
```

### 6.6 Security Considerations

1. **MIME sniffing prevention:** Validate both Content-Type header AND file magic bytes
2. **Filename sanitization:** Never use original filename on disk; generate UUID-based names
3. **Path traversal prevention:** Validate vehicle_id ownership before accepting upload
4. **Virus scanning (future):** Scan uploads with ClamAV before storage
5. **Access control:** Images are served through authenticated endpoint, not direct S3 URLs
6. **Rate limiting:** Max 5 uploads per minute per user

---

## 7. Report Generation Contract

### 7.1 Report Data Structure

```json
{
  "report_id": "rpt_abc123",
  "generated_at": "2026-04-03T10:00:00Z",
  "vehicle": {
    "id": 1,
    "marca": "Toyota",
    "modelo": "Corolla",
    "anio": 2020,
    "motor": "1.8",
    "patente": "ABC123",
    "vin": "1HGBH41JXMN109186",
    "km_actual": 45000,
    "owner": "Juan Perez",
    "registered_at": "2026-01-15T08:00:00Z"
  },
  "status": "ok",
  "status_label": "Al dia",
  "ultimo_service": {
    "fecha": "2026-03-01T10:00:00Z",
    "km": 40000,
    "tipo_aceite": "sintetico",
    "marca_aceite": "Mobil 1",
    "technician": "Carlos Garcia",
    "days_ago": 33
  },
  "proximo_service_km": 50000,
  "km_until_service": 5000,
  "services_count": 5,
  "total_km_covered": 45000,
  "average_service_interval_km": 9000,
  "oil_usage_summary": {
    "mineral": 1,
    "semi": 1,
    "sintetico": 3
  },
  "historial": [
    {
      "fecha": "2026-03-01T10:00:00Z",
      "km": 40000,
      "tipo_aceite": "sintetico",
      "marca_aceite": "Mobil 1",
      "productos": "Filtro de aceite, Filtro de aire",
      "technician": "Carlos Garcia",
      "observaciones": "Service completo"
    }
  ],
  "ownership_history": [
    {
      "owner_name": "Juan Perez",
      "owner_email": "juan@example.com",
      "from": "2026-01-15T08:00:00Z",
      "to": null
    }
  ],
  "pending_appointments": [
    {
      "id": 5,
      "fecha": "2026-04-15T10:00:00Z",
      "tipo_service": "Cambio de aceite",
      "status": "confirmed"
    }
  ]
}
```

### 7.2 PDF Generation Approach

**Decision: Backend-generated PDF**

Rationale:
- Consistent formatting across platforms (iOS/Android)
- Server has access to full data without mobile round-trips
- Can cache generated PDFs
- Easier to maintain one PDF generator than two platform-specific implementations

**Implementation:**
```
Library: gofpdf (pure Go, no external dependencies)
Template: Programmatic layout with company branding
Font: Embedded TrueType (Roboto or similar)
Output: Binary stream → Content-Type: application/pdf
```

**PDF Structure:**
```
┌─────────────────────────────────────┐
│  [Logo] Lubricentros                │
│  Reporte de Vehiculo                │
│  Generado: 03/04/2026 10:00         │
├─────────────────────────────────────┤
│  DATOS DEL VEHICULO                 │
│  Toyota Corolla 2020                │
│  Patente: ABC123 | Motor: 1.8       │
│  KM Actual: 45,000                  │
│  Estado: ✓ Al dia                   │
├─────────────────────────────────────┤
│  ULTIMO SERVICE                     │
│  Fecha: 01/03/2026 | KM: 40,000     │
│  Aceite: Sintetico - Mobil 1        │
│  Tecnico: Carlos Garcia             │
├─────────────────────────────────────┤
│  PROXIMO SERVICE                    │
│  Estimado: 50,000 KM                │
│  Faltan: 5,000 KM                   │
├─────────────────────────────────────┤
│  HISTORIAL COMPLETO                 │
│  ┌─────────────────────────────┐   │
│  │ 01/03/2026 | 40,000 KM      │   │
│  │ Sintetico - Mobil 1         │   │
│  │ Filtro aceite, Filtro aire  │   │
│  ├─────────────────────────────┤   │
│  │ 15/01/2026 | 31,000 KM      │   │
│  │ Semi - Castrol              │   │
│  │ Filtro aceite               │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  RESUMEN DE ACEITES                 │
│  Sintetico: 3 | Semi: 1 | Mineral: 1│
├─────────────────────────────────────┤
│  HISTORIAL DE PROPIETARIOS          │
│  Juan Perez (desde 15/01/2026)      │
└─────────────────────────────────────┘
```

### 7.3 Report Caching Strategy

```
Cache Key: "report:vehicle:{id}:v{version}"
TTL: 1 hour
Invalidation: On new service record creation

Cache Store: In-memory (dev) → Redis (prod)

Versioning:
  - Increment version when vehicle data changes
  - Cache key includes version to avoid stale reports
```

### 7.4 Shareable Link Design (Future)

```
GET /api/v1/reports/share/{token}

Token Structure:
  - JWT with short expiry (7 days)
  - Payload: { "vehicle_id": 1, "exp": ..., "jti": ... }
  - No auth required to view (public link)
  - Read-only access, JSON only (no PDF download without auth)

Response:
  {
    "data": {
      "report": { ... },
      "share_info": {
        "expires_at": "2026-04-10T10:00:00Z",
        "generated_by": "Juan Perez"
      }
    }
  }
```

---

## 8. Cross-Cutting Concerns

### 8.1 Request ID Tracking (Correlation IDs)

```go
// internal/middleware/request_id.go
func RequestIDMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        requestID := r.Header.Get("X-Request-ID")
        if requestID == "" {
            requestID = uuid.New().String()
        }

        ctx := context.WithValue(r.Context(), "request_id", requestID)
        w.Header().Set("X-Request-ID", requestID)

        logger := log.WithField("request_id", requestID)
        ctx = context.WithValue(ctx, "logger", logger)

        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

**Propagation:**
- Client → Server: `X-Request-ID` header
- Server → DB: Include in query comments (for slow query log correlation)
- Server → Logs: Every log line includes `request_id`
- Server → Response: `X-Request-ID` in response headers

### 8.2 Logging Strategy (Structured Logging)

```
Log levels:
  DEBUG: Request/response bodies (dev only), cache hits
  INFO:  Request completed, auth success, business events
  WARN:  Rate limit approaching, slow queries (>100ms), retry attempts
  ERROR: Auth failures, validation errors, DB errors, panics

Structured log format (JSON):
{
  "level": "info",
  "timestamp": "2026-04-03T10:00:00.000Z",
  "request_id": "req_abc123",
  "method": "POST",
  "path": "/api/v1/auth/login",
  "status": 200,
  "duration_ms": 45,
  "remote_addr": "192.168.1.1",
  "user_id": 1,
  "message": "User authenticated successfully"
}

Sensitive field redaction (existing middleware handles this):
  password, password_hash, newPassword, oldPassword,
  password_confirmation, confirmPassword, currentPassword
  → replaced with "[REDACTED]"
```

### 8.3 Rate Limiting Policy

```
Token bucket algorithm per IP + per endpoint

Public endpoints (no auth required):
  AuthRegister    = 3 per 5 minutes   // Prevent spam registrations
  AuthLogin       = 5 per 5 minutes   // Prevent brute force

Authenticated endpoints:
  Default         = 60 per minute     // General API usage
  FileUpload      = 5 per minute      // Prevent storage abuse
  ReportGeneration= 10 per minute     // Prevent PDF generation abuse

Admin endpoints:
  AdminDefault    = 120 per minute    // Higher limit for admin operations

Response headers on rate limit:
  X-RateLimit-Limit: 60
  X-RateLimit-Remaining: 45
  X-RateLimit-Reset: 1712138460
  Retry-After: 300 (only when 429 returned)
```

### 8.4 CORS Configuration

```
Allowed origins by environment:
  development: http://localhost:*, http://127.0.0.1:*
  staging:     https://staging.lubricentros.com
  production:  https://app.lubricentros.com

Headers:
  Access-Control-Allow-Origin: <origin>
  Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
  Access-Control-Allow-Headers: Authorization, Content-Type, X-Request-ID, X-Client-Version
  Access-Control-Allow-Credentials: true
  Access-Control-Max-Age: 86400 (24 hours)
```

### 8.5 API Versioning Strategy

```
URL Path Versioning: /api/v1/...

Version Lifecycle:
  v1 (current): Active development
  v2 (future):   When breaking changes are needed

Breaking changes (require new version):
  - Removing fields from responses
  - Changing field types
  - Changing endpoint paths
  - Changing authentication mechanism

Non-breaking changes (same version):
  - Adding new optional fields to responses
  - Adding new endpoints
  - Adding new optional query parameters
  - Adding new enum values

Deprecation Policy:
  - Announce deprecation 6 months before removal
  - Return Deprecation header: Deprecation: true, Sunset: <date>
  - Log usage of deprecated endpoints
```

### 8.6 Health Check Endpoints

```
GET /health
Response 200:
  {
    "status": "ok",
    "timestamp": "2026-04-03T10:00:00Z",
    "version": "1.0.0",
    "uptime_seconds": 86400
  }

GET /health/ready (readiness probe)
Response 200:
  {
    "status": "ready",
    "checks": {
      "database": { "status": "ok", "latency_ms": 2 },
      "storage":  { "status": "ok" }
    }
  }

Response 503 (not ready):
  {
    "status": "not_ready",
    "checks": {
      "database": { "status": "error", "error": "connection refused" }
    }
  }

GET /health/live (liveness probe)
Response 200: { "status": "alive" }
```

### 8.7 Metrics/Monitoring Hooks

```
Metrics exposed (future: Prometheus /metrics endpoint):
  - http_requests_total{method, path, status}
  - http_request_duration_seconds{method, path}
  - db_connections_active
  - db_connections_idle
  - auth_login_attempts_total{success, failure}
  - file_uploads_total{type, status}
  - report_generations_total{format}

Business metrics:
  - vehicles_registered_total
  - appointments_booked_total
  - services_completed_total
  - ownership_transfers_total

Alerting thresholds (future):
  - Error rate > 5% over 5 minutes
  - P99 latency > 500ms over 5 minutes
  - DB connection pool exhausted
  - Disk usage > 80%
```

---

## 9. Scalability Considerations

### 9.1 Horizontal Scaling Strategy

```
Backend is stateless by design:
  - No session storage in memory
  - JWT validation is stateless (signature + expiry)
  - Refresh token revocation: external store (Redis)
  - File uploads: shared storage (S3)

Scaling unit:
  - Each Go instance can handle ~1000 concurrent requests
  - Auto-scale based on CPU > 70% or request queue depth
  - Minimum: 2 instances (high availability)
  - Maximum: 10 instances (cost control)
```

### 9.2 Database Connection Pooling

```go
// internal/database/db.go (enhanced)
func Connect() (*sql.DB, error) {
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        return nil, err
    }

    // Connection pool configuration
    db.SetMaxOpenConns(25)       // Max simultaneous connections
    db.SetMaxIdleConns(5)        // Idle connections to keep
    db.SetConnMaxLifetime(30 * time.Minute) // Recycle connections
    db.SetConnMaxIdleTime(5 * time.Minute)  // Close idle after 5m

    return db, nil
}

// Sizing formula:
//   max_open_conns = (core_count * 2) + effective_spindle_count
//   For 4-core server: 25 is reasonable
//   Monitor: pg_stat_activity for actual usage
```

### 9.3 Caching Strategy (Redis for Future)

```
Cache Layers:
  L1: In-memory (Go sync.Map) - Hot data, per-instance
      - JWT revocation list (small, fast lookup)
      - Rate limit counters (token buckets)

  L2: Redis (shared) - Warm data, cross-instance
      - Refresh token revocation store
      - Report cache (TTL: 1h)
      - Available slots cache (TTL: 5m)
      - Session data (future)

  L3: PostgreSQL - Cold data, source of truth
      - All persistent data

Cache Invalidation:
  - Write-through: Update cache on write
  - TTL-based: Auto-expire stale data
  - Event-based: Invalidate on specific events (new service, etc.)
```

### 9.4 CDN for Static Assets

```
Future: Serve PDF reports and vehicle images via CDN
  - CloudFront / Cloudflare
  - Cache-Control: public, max-age=3600 (images)
  - Cache-Control: private, no-cache (reports with user data)
  - Signed URLs for private content (S3 presigned URLs)
```

### 9.5 Load Balancing Approach

```
Development:
  - Single instance, direct connection

Staging:
  - 2 instances behind Nginx reverse proxy
  - Round-robin distribution

Production:
  - 2+ instances behind AWS ALB / Cloudflare Load Balancer
  - Health check: GET /health/ready every 30s
  - Sticky sessions: NOT required (stateless backend)
  - SSL termination: At load balancer
```

---

## 10. Deployment Architecture

### 10.1 Development Environment (docker-compose)

```yaml
# docker-compose.dev.yml
version: "3.8"

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: lubricentros_dev
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./backend/migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev"]
      interval: 5s
      timeout: 3s
      retries: 5

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_USER=dev
      - DB_PASSWORD=dev_password
      - DB_NAME=lubricentros_dev
      - JWT_SECRET=dev_secret_change_in_production
      - PORT=8080
      - ENV=development
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./backend:/app
      - ./uploads:/app/uploads

  # Flutter dev runs on host machine, connects to backend:8080

volumes:
  pgdata:
```

### 10.2 Staging Environment

```
Infrastructure:
  - 1x t3.medium (backend, 2 instances)
  - 1x t3.small (PostgreSQL, managed RDS)
  - 1x Nginx reverse proxy
  - S3 bucket for uploads (staging)

Deployment:
  - Manual trigger from main branch
  - Docker images built and pushed to registry
  - docker-compose pull + up -d
  - Database migrations run automatically
```

### 10.3 Production Environment

```
Infrastructure:
  - 2x t3.medium (backend, ECS Fargate or EC2)
  - 1x RDS PostgreSQL (db.t3.small, Multi-AZ)
  - 1x ElastiCache Redis (cache.t3.micro)
  - S3 bucket for uploads (production)
  - CloudFront CDN (future)
  - ALB for load balancing

Security:
  - VPC with private subnets for DB/Redis
  - Security groups: backend → DB, backend → Redis, ALB → backend
  - SSL certificates via ACM
  - WAF rules for common attacks
  - Secrets Manager for DB credentials, JWT secret
```

### 10.4 CI/CD Pipeline Overview

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Push to │───>│   Lint   │───>│   Test   │───>│  Build   │───>│  Deploy  │
│  Branch  │    │          │    │          │    │  Image   │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                                                                        │
                                                            ┌───────────┴───────────┐
                                                            │                       │
                                                      ┌─────▼─────┐         ┌───────▼───────┐
                                                      │  Staging  │         │  Production   │
                                                      │  (auto)   │         │  (manual)     │
                                                      └───────────┘         └───────────────┘

Pipeline Steps:

1. Lint:
   - golangci-lint (backend)
   - flutter analyze (mobile)
   - dart format --set-exit-if-changed

2. Test:
   - go test ./... -race -cover (backend)
   - flutter test (mobile)
   - Security tests (password logging verification)

3. Build:
   - Docker build backend (multi-stage, alpine base)
   - Push to registry (GHCR / ECR)
   - Tag: git sha + branch name

4. Deploy Staging (on push to main):
   - Pull new image
   - Run migrations
   - Rolling restart
   - Health check verification

5. Deploy Production (on tag v*):
   - Manual approval gate
   - Same as staging
   - Post-deploy smoke tests
   - Rollback capability (previous image tag)
```

### 10.5 Database Migration Strategy

```
Tool: Custom migration runner (Go) or golang-migrate

Migration files:
  migrations/
    001_initial_schema.sql
    002_add_patente_vin_to_vehicles.sql
    003_add_ownership_transfers_table.sql
    004_add_deleted_at_soft_delete.sql
    005_add_images_to_services.sql

Execution:
  - Run on application startup (before serving traffic)
  - Atomic: wrapped in transaction
  - Idempotent: safe to run multiple times
  - Version tracked in schema_migrations table

Rollback:
  - Each migration has a down.sql
  - Manual trigger only (never auto-rollback)
  - Backup before migration in production
```

---

## Appendix A: Database Schema (Enhanced)

The current schema (4 tables) needs the following additions for full feature support:

```sql
-- Add to users table
ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user'
    CHECK (role IN ('user', 'admin'));

-- Add to vehicles table
ALTER TABLE vehicles ADD COLUMN patente VARCHAR(20);
ALTER TABLE vehicles ADD COLUMN vin VARCHAR(17);
ALTER TABLE vehicles ADD COLUMN deleted_at TIMESTAMP;  -- Soft delete

-- New table: Ownership transfers
CREATE TABLE ownership_transfers (
    id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL REFERENCES vehicles(id),
    previous_owner_id INT NOT NULL REFERENCES users(id),
    new_owner_id INT NOT NULL REFERENCES users(id),
    transferred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- New table: Refresh token revocation
CREATE TABLE revoked_tokens (
    jti VARCHAR(36) PRIMARY KEY,
    revoked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);
-- Index for cleanup
CREATE INDEX idx_revoked_tokens_expires ON revoked_tokens(expires_at);

-- New table: Schema migrations tracking
CREATE TABLE schema_migrations (
    version INT PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Appendix B: Environment Variables

```bash
# Server
PORT=8080
ENV=development|staging|production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=lubricentros
DB_PASSWORD=<secret>
DB_NAME=lubricentros
DB_SSLMODE=disable  # enable in production

# Authentication
JWT_SECRET=<256-bit-random-string>
JWT_ACCESS_EXPIRY=24h
JWT_REFRESH_EXPIRY=7d

# File Storage
STORAGE_DRIVER=local|s3
STORAGE_LOCAL_PATH=./uploads
STORAGE_S3_BUCKET=lubricentros-uploads
STORAGE_S3_REGION=us-east-1
STORAGE_MAX_IMAGE_SIZE=10485760    # 10MB
STORAGE_MAX_PDF_SIZE=26214400      # 25MB

# Rate Limiting
RATE_LIMIT_AUTH_REGISTER=3/5m
RATE_LIMIT_AUTH_LOGIN=5/5m
RATE_LIMIT_DEFAULT=60/1m
RATE_LIMIT_UPLOAD=5/1m

# Business Hours
BUSINESS_HOURS_START=08:00
BUSINESS_HOURS_END=18:00
BUSINESS_HOURS_SATURDAY_END=13:00
APPOINTMENT_SLOT_DURATION=60

# Redis (future)
REDIS_URL=redis://localhost:6379
```

## Appendix C: Backend Directory Structure (Target)

```
backend/
├── cmd/
│   └── api/
│       └── main.go                 # Entry point
├── internal/
│   ├── api/                        # HTTP handlers
│   │   ├── auth_handler.go
│   │   ├── vehicle_handler.go
│   │   ├── appointment_handler.go
│   │   ├── service_handler.go
│   │   ├── upload_handler.go
│   │   ├── report_handler.go
│   │   └── errors.go              # Error types + helpers
│   ├── middleware/
│   │   ├── logging.go             # Existing + structured logging
│   │   ├── auth.go                # JWT validation
│   │   ├── cors.go
│   │   ├── rate_limiter.go
│   │   ├── request_id.go
│   │   └── recovery.go
│   ├── service/                    # Business logic
│   │   ├── auth_service.go
│   │   ├── vehicle_service.go
│   │   ├── appointment_service.go
│   │   ├── service_service.go
│   │   ├── report_service.go
│   │   └── upload_service.go
│   ├── repository/                 # Data access
│   │   ├── user_repo.go
│   │   ├── vehicle_repo.go
│   │   ├── appointment_repo.go
│   │   └── service_repo.go
│   ├── database/
│   │   └── db.go                  # Existing + pool config
│   └── config/
│       └── config.go              # Env var loading
├── migrations/
│   ├── 001_initial_schema.sql
│   └── ...
├── uploads/                        # Local file storage (dev)
├── go.mod
└── go.sum
```

## Appendix D: Mobile Directory Structure (Target)

```
mobile/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   ├── routes.dart
│   │   └── api_config.dart        # Base URL, timeouts
│   ├── models/
│   │   ├── user.dart
│   │   ├── vehicle.dart
│   │   ├── appointment.dart
│   │   ├── service_record.dart    # NEW
│   │   └── report.dart            # NEW
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── vehicle_provider.dart
│   │   ├── appointment_provider.dart
│   │   └── report_provider.dart   # NEW
│   ├── services/
│   │   ├── api_client.dart
│   │   ├── auth_service.dart
│   │   ├── vehicle_service.dart
│   │   ├── appointment_service.dart
│   │   ├── report_service.dart    # NEW
│   │   ├── storage_service.dart   # Enhance with flutter_secure_storage
│   │   └── sync_service.dart      # NEW: offline sync
│   ├── screens/
│   │   ├── auth/
│   │   ├── vehicles/
│   │   ├── appointments/
│   │   ├── reports/               # NEW
│   │   └── profile/               # NEW
│   ├── widgets/
│   │   ├── loading/
│   │   ├── vehicle_card.dart
│   │   └── ...
│   ├── utils/
│   │   └── secure_logger.dart
│   └── theme/
│       └── app_theme.dart
├── pubspec.yaml
└── ...
```
