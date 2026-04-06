# Flujo de Trabajo para Agentes - Proyecto Lubricentros

## Objetivo

Establecer un flujo donde cada agente trabaje en su propia rama de feature, haga commits atómicos, y cree Pull Requests hacia ramas de desarrollo (nunca directamente a `main`).

---

## Ramas del Proyecto

```
main                    ← Producción (nunca hacer PR directo aquí)
├── develop             ← Rama de integración
│   ├── feature/auth-implementation
│   ├── feature/vehicle-crud
│   └── feature/appointment-ui
└── bugfix/login-issue  ← Ramas de bugfix
```

> **Regla de oro**: NUNCA hacer push o PR directo a `main`. Todo pasa por `develop` o ramas de feature.

---

## Flujo para Agentes

### 1. Iniciar una Feature Nueva

```bash
# Siempre desde develop actualizada
git checkout develop
git pull origin develop

# Crear rama de feature con prefijo claro
git checkout -b feature/nombre-del-agente/descripcion-corta
```

Ejemplos de nombres de rama:
- `feature/mauro/auth-login-screen`
- `feature/ai-backend/vehicle-api`
- `feature/ai-mobile/appointment-list`

### 2. Commits Atómicos

Cada commit debe ser:
- **Atómico**: Una sola cosa (un cambio lógico)
- **Mensaje convencional**: Formato conventional commits

```bash
git add archivo_modificado.go
git commit -m "feat(auth): add login endpoint validation"

git add otro_archivo.dart  
git commit -m "fix(auth): correct password field type"
```

#### Prefijos permitidos

| Tipo | Descripción |
|------|-------------|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `refactor` | Refactorización sin cambio de comportamiento |
| `test` | Agregar o corregir tests |
| `docs` | Documentación |
| `chore` | Tareas de mantenimiento |
| `style` | Formateo, linters |
| `ci` | Cambios en workflows |

### 3. Subir la Rama

```bash
# Primera vez: subir con tracking
git push -u origin feature/nombre-agente/descripcion

# Commits siguientes
git push
```

### 4. Crear Pull Request

```bash
# Desde la rama de feature
gh pr create \
  --title "feat(auth): Implementar login con validación" \
  --body "$(cat <<'EOF'
## Resumen
- Agregar endpoint POST /auth/login
- Validación de email y password
- Retornar JWT token

## Cambios
- `internal/handler/auth_handler.go`
- `internal/usecase/auth_usecase.go`

## Testing
- [ ] Tests unitarios pasando
- [ ] Tests de integración pasando
EOF
)"
```

---

## Checklist Pre-PR

Antes de crear el PR, el agente debe verificar:

- [ ] La rama tiene commits atómicos con mensajes claros
- [ ] Los tests pasan localmente
- [ ] El linter pasa (`golangci-lint run` / `flutter analyze`)
- [ ] No hay passwords en logs
- [ ] La rama está actualizada con `develop` (si aplica, hacer rebase)
- [ ] Se creó el PR hacia `develop` (no hacia `main`)

---

## Workflow de GitHub Actions

El proyecto tiene un workflow de seguridad que se ejecuta en cada PR:

```yaml
# Se ejecuta en push/PR a main y develop
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
```

### Acciones que ocurren automáticamente

1. **Checkout** del código
2. **Setup** de Go y Flutter
3. **Security scan** (sin passwords en logs)
4. **Backend tests** (`go test`)
5. **Mobile tests** (`flutter test`)
6. **Linting** (golangci-lint, flutter analyze)

### Estados del PR

| Estado | Significado |
|--------|--------------|
| ✅ All checks passed | Listo para hacer merge |
| ❌ Checks failed | Corregir errores antes de merge |
| 🔄 Pending | Ejecutando checks |

---

## Merge del PR

Una vez que todos los checks pasan y un humano aprueba:

```bash
# En develop
git checkout develop
git pull origin develop
git merge feature/nombre-agente/descripcion
git push origin develop
```

O usar el botón "Squash and merge" en GitHub.

---

## Reglas Importantes

1. **Una feature por rama**: Cada agente trabaja en una sola feature
2. **Commits pequeños**: Evitar commits grandes que incluyan múltiples cambios
3. **Nunca a main**: Todo PR va hacia `develop`
4. **Tests primero**: Escribir tests antes o junto con el código
5. **Descriptive PRs**: El título y descripción deben explicar qué y por qué

---

## Ejemplo Completo

```bash
# 1. Starting
git checkout develop
git pull
git checkout -b feature/mauro/login-screen

# 2. Working (commits atómicos)
git add mobile/lib/screens/login_screen.dart
git commit -m "feat(auth): create login screen UI"

git add mobile/lib/providers/auth_provider.dart
git commit -m "feat(auth): connect login provider to screen"

# 3. Push
git push -u origin feature/mauro/login-screen

# 4. Create PR via GitHub CLI
gh pr create --title "feat(auth): add login screen" --base develop
```

---

## Errores Comunes y Cómo Evitarlos

| Error | Solución |
|-------|----------|
| Push a main directamente | Siempre hacer PR a `develop` |
| Commits grandes ("wip", "stuff") | Commits atómicos con mensajes claros |
| Tests rotos en PR | Corregir antes de crear PR |
| Conflictos | hacer `git rebase develop` antes de push |
