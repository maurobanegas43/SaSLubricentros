# Diseño de Arquitectura — Lubricentros SaaS

**Fecha:** 3 de Abril, 2026  
**Estado:** Diseño aprobado, listo para implementación  
**Versión:** 1.0

---

## 1. Visión General

Sistema SaaS para gestión de lubricentros: turnos, vehículos, historial de mantenimiento, transferencia de propiedad y reportes PDF.

### Estado Actual del Proyecto

| Componente | Progreso | Estado |
|------------|----------|--------|
| Backend Go | ~15% | Skeleton con gorilla/mux, logging middleware, schema SQL |
| Mobile Flutter | ~30% | 8 pantallas UI, Provider, datos mock, dev mode |
| Base de datos | ~20% | 4 tablas básicas definidas, sin migraciones completas |
| Integración | 0% | Sin conexión real mobile ↔ backend |

### Lo que este diseño define

- Migración gorilla/mux → Gin con Clean Architecture
- Schema completo de base de datos (12+ tablas)
- Arquitectura mobile con offline-first
- Contratos de API completos
- Plan de implementación en 4 fases

---

## 2. Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                     MOBILE APP (Flutter)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ Screens  │→ │ Providers│→ │  Domain  │  │ Local Storage│   │
│  │   (16)   │  │(Provider)│  │ UseCases │  │  (sqflite)   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS + JWT Bearer
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BACKEND API (Go + Gin)                       │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │
│  │ Router  │→ │ Handlers │→ │ UseCases │→ │ Repositories   │  │
│  │ (Gin)   │  │  (thin)  │  │(business)│  │  (postgres)    │  │
│  └─────────┘  └──────────┘  └──────────┘  └────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Middleware Chain: Recovery → Logging → CORS → RateLimit  │  │
│  │                   → RequestID → Auth → Role              │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │ File Storage │  │   JWT Mgr    │  │   Config + Env Vars  │ │
│  │ (local→S3)   │  │ (HS256+RT)   │  │   (godotenv)         │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
┌─────────────────────────┐  ┌─────────────────────────┐
│    PostgreSQL (prod)    │  │  File Storage (local)   │
│    SQLite (dev/test)    │  │  → S3 (future)          │
└─────────────────────────┘  └─────────────────────────┘
```

### Protocolos y Conexiones

| Conexión | Protocolo | Auth | Dirección |
|----------|-----------|------|-----------|
| Mobile → Backend | HTTPS REST | JWT Bearer | Unidireccional |
| Backend → DB | TCP (lib/pq) | DB credentials | Bidireccional |
| Backend → Storage | Filesystem/S3 API | IAM (future) | Bidireccional |

---

## 3. Estructura de Carpetas

### Backend (Go + Gin)

```
backend/
├── cmd/api/
│   ├── main.go                 # Entry point + graceful shutdown
│   └── server.go               # Router setup, middleware chain
├── internal/
│   ├── domain/
│   │   ├── entity/             # User, Vehicle, Appointment, ServiceRecord, Product, ImageAttachment
│   │   ├── repository/         # Interfaces (UserRepository, VehicleRepository, etc.)
│   │   ├── usecase/            # Interfaces (AuthUsecase, VehicleUsecase, etc.)
│   │   └── errors/             # Domain error types + codes
│   ├── usecase/                # Implementaciones de casos de uso
│   ├── repository/
│   │   ├── postgres/           # Implementaciones PostgreSQL
│   │   └── mocks/              # Mocks para testing
│   ├── handler/                # HTTP handlers (Gin)
│   ├── middleware/             # Auth, Role, CORS, RateLimit, Recovery, Logging, RequestID
│   ├── dto/
│   │   ├── request/            # Request DTOs con validación
│   │   └── response/           # Response DTOs + paginación
│   ├── database/               # Connection pool, migration runner, transactions
│   └── service/
│       ├── storage/            # File storage interface + local + S3
│       └── email/              # Email service interface + SMTP
├── migrations/                 # goose migrations (up/down)
├── config/                     # Config centralizada (env + validación)
├── pkg/
│   ├── jwt/                    # Token generation/validation
│   ├── hash/                   # bcrypt wrapper
│   ├── validator/              # Custom validators
│   ├── response/               # JSON response helpers
│   └── pagination/             # Pagination utilities
├── tests/
│   ├── integration/
│   └── testutil/
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── Makefile
└── go.mod
```

### Mobile (Flutter)

```
mobile/lib/
├── main.dart
├── core/
│   ├── constants/              # API URLs, route names, storage keys
│   ├── theme/                  # AppTheme, colors, typography
│   ├── utils/                  # SecureLogger, formatters, validators, AsyncValue<T>
│   └── errors/                 # Failure classes, exceptions
├── data/
│   ├── datasources/
│   │   ├── remote/             # API calls (Dio)
│   │   └── local/              # SQLite cache (sqflite)
│   ├── repositories/           # Implementaciones con offline-first logic
│   └── models/                 # DTOs con fromJson/toJson
├── domain/
│   ├── entities/               # Pure Dart entities
│   ├── repositories/           # Abstract interfaces
│   └── usecases/               # Use case classes
├── presentation/
│   ├── screens/                # 16 screens total
│   ├── widgets/                # Reusable widgets
│   ├── providers/              # ChangeNotifier state management
│   └── navigation/             # Route configuration + guards
└── di/                         # Dependency injection
```

---

## 4. Decisiones de Arquitectura Clave

### 4.1 Backend

| Decisión | Elección | Por qué |
|----------|----------|---------|
| Framework | **Gin** (migrar de gorilla/mux) | 40x más rápido (radix tree), middleware chain nativo, integración con validator |
| DB Access | **database/sql** puro | Standard, portable SQLite↔PostgreSQL, sin magia |
| Migrations | **goose** | Single-file, embeddable, corre desde el binario |
| Validación | **go-playground/validator/v10** | Integración nativa con Gin, battle-tested |
| DI | **Google Wire** | Compile-time, zero runtime overhead, fail-fast |
| Password Hash | **bcrypt (cost 12)** | Standard de la industria, ya en security guidelines |
| JWT | **HS256 + refresh rotation** | Simple, seguro, rotation previene token theft |
| File Storage | **Interface + local impl** | S3-ready, validado, size-limited, UUID filenames |
| Error Handling | **Domain error types** | Structured, testable, nunca leak internals |

### 4.2 Mobile

| Decisión | Elección | Por qué |
|----------|----------|---------|
| State Management | **Provider** (mantener) | Ya implementado, costo de migración no justificado |
| HTTP Client | **Dio** (upgrade de http) | Interceptors esenciales para auth, retry, logging |
| Secure Storage | **flutter_secure_storage** | Non-negotiable para tokens (Keychain/Keystore) |
| Offline Cache | **sqflite** | Ya en deps, perfecto para caching layer |
| PDF | **pdf + printing** | Generación nativa, share/print integrado |
| Forms | **formz** | Type-safe form states, validators reutilizables |
| Pattern | **AsyncValue<T>** | Unified loading/data/error states |

### 4.3 Base de Datos

| Decisión | Elección | Por qué |
|----------|----------|---------|
| Primary Keys | **UUID** | No guessable, distributed-friendly, merge-safe para offline sync |
| Ownership | **vehicle_owners junction table** | Partial unique index enforce un solo owner actual |
| Service Records | **INMUTABLES** | Sin updated_at, trigger bloquea UPDATE/DELETE, REVOKE a nivel DB |
| Correcciones | **service_addendums** | Addendum pattern: nunca se modifica el original |
| Time Slots | **Exclusion constraints (btree_gist)** | Prevención de double-booking a nivel DB |
| Audit | **audit_log con JSONB** | Triggers automáticos, old_data/new_data completos |

---

## 5. API Endpoints

### Auth
```
POST   /api/v1/auth/register       → AuthResponse{access_token, refresh_token, user}
POST   /api/v1/auth/login          → AuthResponse{access_token, refresh_token, user}
POST   /api/v1/auth/refresh        → AuthResponse{access_token, refresh_token}
POST   /api/v1/auth/logout         → {message}
```

### Vehicles
```
GET    /api/v1/vehicles            → PaginatedResponse{vehicles}
POST   /api/v1/vehicles            → Vehicle
GET    /api/v1/vehicles/:id        → Vehicle
PUT    /api/v1/vehicles/:id        → Vehicle
DELETE /api/v1/vehicles/:id        → {message}
POST   /api/v1/vehicles/:id/transfer → {message}
GET    /api/v1/vehicles/:id/history → PaginatedResponse{services}
GET    /api/v1/vehicles/:id/report  → VehicleReport
```

### Appointments
```
GET    /api/v1/appointments         → PaginatedResponse{appointments}
POST   /api/v1/appointments         → Appointment
PUT    /api/v1/appointments/:id     → Appointment
DELETE /api/v1/appointments/:id     → {message}
GET    /api/v1/appointments/available-slots → {slots}
```

### Services (admin write, client read)
```
POST   /api/v1/services             → ServiceRecord (admin only)
GET    /api/v1/services/vehicle/:id → PaginatedResponse{services}
```

### Uploads
```
POST   /api/v1/uploads              → ImageAttachment (multipart)
GET    /api/v1/uploads/:id          → ImageAttachment
```

### Health
```
GET    /health                      → {status: "ok"}
GET    /ready                       → {status: "ready"} (con DB check)
```

---

## 6. Contratos Clave

### 6.1 Error Response Standard

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

### 6.2 JWT Token Structure

- **Access Token**: 15 min expiry, claims: user_id, email, role
- **Refresh Token**: 7 days expiry, stored as hash in DB, rotation con reuse detection
- **Rotation**: cada refresh invalida el token anterior y genera uno nuevo

### 6.3 RBAC Matrix

| Endpoint | user | admin |
|----------|------|-------|
| GET /vehicles | own | all |
| POST /vehicles | ✓ | ✓ |
| PUT /vehicles/:id | own | all |
| DELETE /vehicles/:id | own | all |
| POST /vehicles/:id/transfer | own | — |
| POST /appointments | ✓ | ✓ |
| POST /services | — | ✓ |
| GET /services/vehicle/:id | own | all |

---

## 7. Plan de Implementación

### Fase 1: Backend Core (Semanas 1-3)
- [ ] Migrar gorilla/mux → Gin
- [ ] Config + centralized env loading
- [ ] JWT auth (register, login, refresh, logout)
- [ ] Middleware chain (auth, role, CORS, rate limit, recovery, logging, request ID)
- [ ] Vehicle CRUD endpoints
- [ ] Appointment CRUD endpoints
- [ ] Service record endpoints (admin write)
- [ ] File upload endpoint
- [ ] Migrations completas con goose
- [ ] Docker compose para desarrollo

### Fase 2: Mobile Integration (Semanas 4-5)
- [ ] Migrar http → Dio con interceptors
- [ ] Implementar flutter_secure_storage
- [ ] Refactor providers con AsyncValue<T>
- [ ] Wire todas las pantallas existentes a API real
- [ ] Auth guard en routing
- [ ] Desactivar dev mode

### Fase 3: Offline-First (Semanas 6-7)
- [ ] sqflite schema + DatabaseHelper
- [ ] Local data sources
- [ ] Repository offline-first logic (cache-first, network-refresh)
- [ ] ConnectivityProvider
- [ ] SyncEngine con pending_mutations queue
- [ ] Offline indicators en UI

### Fase 4: Features Completas (Semanas 8-10)
- [ ] 8 pantallas nuevas (forgot password, transfer, calendar, history, reports, profile, settings)
- [ ] ServiceHistoryTimeline widget
- [ ] VehicleReportScreen con PDF generation
- [ ] TransferOwnershipScreen
- [ ] Tests unitarios (80%+ coverage)
- [ ] Tests de integración backend
- [ ] Production config + CI/CD

---

## 8. Entidades del Dominio

### User
```go
type User struct {
    ID           int64     `json:"id"`
    Email        string    `json:"email"`
    PasswordHash string    `json:"-"`
    Name         string    `json:"name"`
    Phone        string    `json:"phone,omitempty"`
    Role         Role      `json:"role"` // client | admin
    CreatedAt    time.Time `json:"created_at"`
    UpdatedAt    time.Time `json:"updated_at"`
}
```

### Vehicle
```go
type Vehicle struct {
    ID        int64     `json:"id"`
    UserID    int64     `json:"user_id"`
    Marca     string    `json:"marca"`
    Modelo    string    `json:"modelo"`
    Anio      int       `json:"anio"`
    Motor     string    `json:"motor,omitempty"`
    KmActual  int       `json:"km_actual"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

### Appointment
```go
type Appointment struct {
    ID            int64             `json:"id"`
    UserID        int64             `json:"user_id"`
    VehicleID     int64             `json:"vehicle_id"`
    Fecha         time.Time         `json:"fecha"`
    TipoService   string            `json:"tipo_service"`
    Status        AppointmentStatus `json:"status"`
    Observaciones string            `json:"observaciones,omitempty"`
    CreatedAt     time.Time         `json:"created_at"`
    UpdatedAt     time.Time         `json:"updated_at"`
}
```

### ServiceRecord (inmutable)
```go
type ServiceRecord struct {
    ID               int64     `json:"id"`
    VehicleID        int64     `json:"vehicle_id"`
    AppointmentID    *int64    `json:"appointment_id,omitempty"`
    Fecha            time.Time `json:"fecha"`
    Km               int       `json:"km"`
    TipoAceite       OilType   `json:"tipo_aceite"`
    MarcaAceite      string    `json:"marca_aceite,omitempty"`
    Productos        string    `json:"productos,omitempty"`
    Observaciones    string    `json:"observaciones,omitempty"`
    ProximoServiceKm int       `json:"proximo_service_km"`
    CreatedAt        time.Time `json:"created_at"`
    // NO UpdatedAt — inmutable por diseño
}
```

---

## 9. Flujo de Transferencia de Propiedad

```
1. REQUEST: Owner actual inicia transferencia
   → ownership_transfers.status = 'requested'
   → vehicle_owners: owner actual sigue is_current=true

2. VALIDATE: Sistema verifica
   → No hay turnos pendientes bloqueantes
   → Target user existe y está activo
   → Target user no es ya owner

3. COMPLETE: Transacción atómica
   a. vehicle_owners: old owner → is_current=false
   b. vehicle_owners: new owner → is_current=true
   c. ownership_transfers: status = 'completed'
   d. Turnos pendientes → transferidos al nuevo owner
   e. Log en audit_log

4. REJECT: Si validación falla
   → ownership_transfers.status = 'rejected'
   → Sin cambios en vehicle_owners
```

---

## 10. Inmutabilidad de Service Records

Tres capas de protección:

1. **Sin columna `updated_at`** — La ausencia señala intención
2. **BEFORE trigger** — RAISE EXCEPTION en UPDATE/DELETE: "service_records are IMMUTABLE. Use service_addendums for corrections"
3. **REVOKE a nivel DB** — `REVOKE UPDATE, DELETE ON service_records FROM app_user`

### Patrón de Corrección (Addendum)

```
Original Record (IMMUTABLE):
  id: abc123, km: 15000, tipo_aceite: "mineral", ...

Correction via Addendum:
  service_id: abc123
  field_name: "km"
  old_value: "15000"
  new_value: "14500"
  reason: "Typo in original entry"
  created_by: mechanic_id
  created_at: 2026-04-03
```

---

## 11. Offline-First Strategy

### Cache-First, Network-Refresh

```
READ:
  1. Intentar cache SQLite
  2. Si cache fresco (< 5 min appointments, < 30 min vehicles) → retornar
  3. Si no, intentar network
  4. Si network ok → actualizar cache, retornar
  5. Si network fail → retornar cache stale (si existe)

WRITE (offline):
  1. Guardar en pending_mutations queue
  2. Aplicar cambio localmente (optimistic update)
  3. UI muestra banner "offline" (non-blocking)

SYNC (reconnection):
  1. Procesar pending_mutations en orden FIFO
  2. Cada mutación: POST/PUT/DELETE a API
  3. Success → remover de queue, actualizar cache
  4. Failure → retry (max 3), luego marcar como failed
  5. Después de todas → full data refresh
```

### Entidades Cached

| Entidad | Cache TTL | Rationale |
|---------|-----------|-----------|
| Vehicles | 30 min | Core data, rarely changes |
| Appointments | 5 min | Time-sensitive |
| Service History | 24 horas | Historical, read-heavy, never changes |
| User Profile | 1 hora | Static data |

---

## 12. Próximos Pasos

1. **Iniciar Fase 1 del backend** — Migrar a Gin, implementar auth
2. **Completar migraciones de DB** — Schema completo con goose
3. **Wire mobile a API real** — Eliminar mock data, activar servicios
4. **Iterar sobre diseño** — Ajustar según feedback durante implementación

---

*Documento generado por análisis de 4 agentes especializados: Backend Architect, Flutter Specialist, Database Designer, System Designer.*
