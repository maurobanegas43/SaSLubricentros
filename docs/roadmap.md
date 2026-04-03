# Roadmap

## Fase 1: MVP Backend (Semana 1-2)

### Backend Core
- [ ] Setup proyecto Go + estructura
- [ ] Conexión PostgreSQL
- [ ] Migraciones iniciales
- [ ] Auth: register + login (JWT)
- [ ] Middleware de autenticación

### API Vehicles
- [ ] CRUD vehicles
- [ ] Validaciones
- [ ] Tests básicos

### API Appointments
- [ ] CRUD appointments
- [ ] Validación de solapamiento
- [ ] Cambio de estados

## Fase 2: MVP Mobile (Semana 3-4) ✅ 85% COMPLETADA

### Mobile Setup
- ✅ Estructura Flutter
- ✅ Navegación (rutas)
- ✅ Theme y estilos base (Modern Industrial)
- ⚠️ SQLite setup (pendiente - usando in-memory)

### Pantallas Cliente
- ✅ Login / Register
- ✅ Lista de vehículos
- ✅ Detalle de vehículo
- ✅ Crear turno
- ✅ Lista de turnos

### Integración API
- ✅ HTTP client
- ✅ Auth interceptor
- ✅ Error handling
- ⚠️ Cache con SQLite (pendiente)

## Fase 3: Historial y Reportes (Semana 5-6)

### Backend Services
- [ ] POST /services (registrar service)
- [ ] GET /vehicles/:id/services
- [ ] GET /vehicles/:id/report
- [ ] Cálculo de próximo service
- [ ] Cálculo de estado del vehículo

### Mobile Historial
- [ ] Pantalla de historial
- [ ] Reporte del vehículo (KEY FEATURE)
- [ ] Visualización de próximo service
- [ ] Indicadores de estado

## Fase 4: Admin Features (Semana 7-8)

### Backend Admin
- [ ] Roles (user/admin)
- [ ] Endpoints admin
- [ ] Dashboard data

### Mobile Admin (opcional)
- [ ] Vista de turnos del día
- [ ] Registro rápido de service
- [ ] Historial de cliente

## Fase 5: Polish (Semana 9-10)

### UX/UI
- [ ] Loading states
- [ ] Animaciones
- [ ] Feedback visual
- [ ] Manejo de errores mejorado

### Testing
- [ ] Tests backend
- [ ] Tests mobile (widgets)
- [ ] Tests de integración

### Deploy
- [ ] Docker setup
- [ ] CI/CD básico
- [ ] Deploy staging

## Backlog

### Features Futuros
- [ ] Notificaciones push
- [ ] Recordatorios de service
- [ ] Multi-tenant
- [ ] Panel web admin
- [ ] Reportes avanzados
- [ ] Integración con pagos

### Optimizaciones
- [ ] Caché avanzado
- [ ] Sincronización offline
- [ ] Compresión de imágenes
- [ ] Paginación optimizada
