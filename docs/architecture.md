# Arquitectura

## Decisiones Técnicas

### Stack Tecnológico

- **Mobile**: Flutter + SQLite (cache/offline)
- **Backend**: Go + Gorilla Mux
- **Base de Datos**: PostgreSQL
- **API**: REST
- **Infraestructura**: Preparado para multi-tenant

### Arquitectura General

```
[Mobile App Flutter] 
       ↓ REST API
[Backend Go]
       ↓
[PostgreSQL]
```

**Características:**
- Mobile-first con capacidad offline
- Backend stateless para escalabilidad
- SQLite en mobile para cache y operación sin conexión

## Decisiones de Diseño

### Decisión 1: Go para Backend
- **Contexto**: Necesidad de escalabilidad y rendimiento
- **Decisión**: Go con Gorilla Mux para API REST
- **Consecuencias**: Mejor performance, fácil deployment, preparado para multi-tenant

### Decisión 2: Flutter para Mobile
- **Contexto**: App mobile como cliente principal
- **Decisión**: Flutter para desarrollo cross-platform
- **Consecuencias**: Un solo codebase para iOS y Android

### Decisión 3: SQLite Local
- **Contexto**: Usuarios necesitan acceso offline
- **Decisión**: SQLite en mobile para cache
- **Consecuencias**: Mejor UX, sincronización necesaria

### Decisión 4: Historial como Fuente de Verdad
- **Contexto**: Integridad de datos del vehículo
- **Decisión**: Tabla services es inmutable, estado del vehículo se calcula
- **Consecuencias**: Datos consistentes, auditoría completa

## Patrones de Diseño

- **Repository Pattern**: Abstracción de acceso a datos
- **REST API**: Comunicación cliente-servidor
- **Event Sourcing (parcial)**: Historial de services inmutable

## Seguridad

- JWT para autenticación
- Passwords hasheados (bcrypt)
- HTTPS en producción
- Validación de datos en backend
- Rate limiting en endpoints públicos

## Escalabilidad

- Backend stateless (horizontal scaling)
- Conexión pool a PostgreSQL
- Índices en queries frecuentes
- Preparado para multi-tenant (futuro)
