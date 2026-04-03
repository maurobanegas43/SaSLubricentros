# Proposal: Backend Persistence and Business Logic

## Intent

The Lubricentros backend is a skeleton with domain entities and repository interfaces but zero implementations. No database connection works, no API endpoints exist, and the project has conflicting database drivers (PostgreSQL in `db.go` vs MariaDB in `mariadb.go`). This change delivers a working persistence layer and core business logic so the mobile app can communicate with real data.

## Scope

### In Scope
- MariaDB connection setup (replace PostgreSQL `db.go` with `mariadb.go`)
- Repository implementations for all 8 entities (user, vehicle, appointment, service_record, product, refresh_token, ownership_transfer, attachment)
- Usecase layer for auth (register/login/refresh/revoke), vehicles (CRUD), appointments (CRUD + status flow), services (create + history)
- JWT auth middleware (token validation, role-based access)
- Password hashing package (bcrypt)
- Standardized error handling and response format
- Input validation via `go-playground/validator`
- `.env` configuration for MariaDB

### Out of Scope
- Mobile app changes (separate change)
- File storage / attachments upload (future)
- Admin dashboard features (future)
- Report generation (future)
- Integration tests with real MariaDB (future)

## Capabilities

### New Capabilities
- `database-mariadb`: MariaDB connection pool, health check, migration execution
- `user-auth`: Registration, login, JWT token generation/refresh/revocation, password hashing
- `vehicle-management`: CRUD operations with ownership validation
- `appointment-scheduling`: Appointment creation, status transitions, conflict detection
- `service-history`: Immutable service record creation with parts tracking
- `security-middleware`: JWT validation middleware, input validation, error standardization

### Modified Capabilities
- None (no existing capabilities to modify)

## Approach

1. **Clean up**: Remove `internal/database/db.go` (PostgreSQL), fix `go.mod` (remove `lib/pq`, add `gorilla/mux`)
2. **Wire MariaDB**: Use existing `infrastructure/database/mariadb.go` as the sole connection layer
3. **Implement repositories**: MySQL implementations using `database/sql` + prepared statements, one per entity
4. **Build usecases**: AuthUsecase, VehicleUsecase, AppointmentUsecase, ServiceUsecase — each depending on repository interfaces
5. **Add middleware**: JWT auth middleware, request validation middleware
6. **Create handlers**: HTTP handlers wiring usecases to gorilla/mux routes
7. **Standardize responses**: JSON response envelope with consistent error format

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `backend/internal/database/db.go` | Removed | PostgreSQL code, replaced by mariadb.go |
| `backend/internal/infrastructure/database/mariadb.go` | Modified | Add migration auto-run |
| `backend/internal/infrastructure/repository/` | New | 8 MySQL repository implementations |
| `backend/internal/usecase/` | New | Auth, vehicle, appointment, service usecases |
| `backend/internal/handler/` | New | HTTP handlers for all endpoints |
| `backend/internal/middleware/auth.go` | New | JWT validation middleware |
| `backend/pkg/hash/` | New | bcrypt password hashing |
| `backend/pkg/response/` | New | Standardized JSON responses |
| `backend/cmd/api/main.go` | Modified | Wire DB, middleware, routes |
| `backend/.env.example` | Modified | MariaDB + JWT env vars |
| `backend/go.mod` | Modified | Remove lib/pq, add gorilla/mux |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| MariaDB not installed locally | Medium | Provide Docker Compose fallback |
| Scope creep into handlers/mobile | Medium | Strict boundary — only persistence + usecases |
| go.mod dependency conflicts | Low | Clean go.mod, run `go mod tidy` |
| Repository SQL queries with MariaDB dialect issues | Low | Use existing migration as reference, test queries |

## Rollback Plan

1. `git revert` the change branch — all changes are additive except `db.go` removal
2. Keep `db.go` in a `deprecated/` folder before deletion for easy recovery
3. MariaDB migration is idempotent (`CREATE TABLE IF NOT EXISTS`) — safe to re-run

## Dependencies

- MariaDB 10.6+ running locally (or Docker container)
- Go 1.22+ toolchain
- `go mod download` to fetch dependencies

## Success Criteria

- [ ] `go run cmd/api/main.go` starts without errors
- [ ] MariaDB connection established and migrations applied
- [ ] POST `/api/auth/register` creates user with hashed password
- [ ] POST `/api/auth/login` returns valid JWT access + refresh tokens
- [ ] GET `/api/vehicles` returns user's vehicles (authenticated)
- [ ] POST `/api/appointments` creates appointment with conflict detection
- [ ] All repository methods return proper domain errors
- [ ] Passwords never appear in logs (existing middleware verified)
- [ ] `go vet` and `go build` pass cleanly
