# SaaS Lubricentros

Sistema para digitalizar lubricentros en Argentina.

## Stack

- **Mobile**: Flutter + SQLite
- **Backend**: Go + PostgreSQL
- **API**: REST

## Estructura del Proyecto

```
/mobile     - App Flutter (cliente)
/backend    - API en Go
/docs       - Documentación
```

## Quick Start

### Backend
```bash
cd backend
go mod download
go run cmd/api/main.go
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## Security

This project implements comprehensive password security measures:

- 🔒 Automatic password redaction in logs (backend & mobile)
- 🔒 Pre-commit hooks to prevent password logging
- 🔒 Security tests to verify password protection
- 🔒 Database uses bcrypt hashes (never plaintext)

**Setup Security Measures**:
```bash
# Install git hooks
./setup-git-hooks.sh

# Verify security compliance
./scripts/verify-password-security.sh
```

**For Developers**:
- Backend: Use `LoggingMiddleware` for automatic password redaction
- Mobile: Use `SecureLogger` instead of print/debugPrint
- See: `docs/security-guidelines.md` for complete guidelines

## Documentación

Ver carpeta `/docs` para más detalles sobre arquitectura, API y base de datos.
