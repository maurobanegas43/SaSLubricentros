# API

## Base URL
```
http://localhost:8080/api/v1
```

## Autenticación

Todas las rutas (excepto `/auth/*`) requieren JWT en header:
```
Authorization: Bearer <token>
```

---

## Endpoints

### Autenticación

#### POST /api/v1/auth/register
Registra un nuevo usuario.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "Juan Pérez",
  "phone": "+54911234567"
}
```

**Response:**
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "Juan Pérez"
  }
}
```

#### POST /api/v1/auth/login
Autentica un usuario.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "Juan Pérez"
  }
}
```

---

### Vehicles

#### GET /api/v1/vehicles
Lista vehículos del usuario autenticado.

**Response:**
```json
{
  "vehicles": [
    {
      "id": 1,
      "marca": "Toyota",
      "modelo": "Corolla",
      "anio": 2020,
      "motor": "1.8",
      "km_actual": 45000
    }
  ]
}
```

#### POST /api/v1/vehicles
Crea un nuevo vehículo.

**Request:**
```json
{
  "marca": "Toyota",
  "modelo": "Corolla",
  "anio": 2020,
  "motor": "1.8",
  "km_actual": 45000
}
```

#### PUT /api/v1/vehicles/:id
Actualiza km_actual del vehículo.

**Request:**
```json
{
  "km_actual": 46000
}
```

#### DELETE /api/v1/vehicles/:id
Elimina un vehículo.

---

### Appointments

#### GET /api/v1/appointments
Lista turnos del usuario.

**Query Parameters:**
- `status` (opcional): pending | confirmed | completed

**Response:**
```json
{
  "appointments": [
    {
      "id": 1,
      "vehicle_id": 1,
      "fecha": "2026-04-15T10:00:00Z",
      "tipo_service": "Cambio de aceite",
      "status": "confirmed"
    }
  ]
}
```

#### POST /api/v1/appointments
Crea un turno.

**Request:**
```json
{
  "vehicle_id": 1,
  "fecha": "2026-04-15T10:00:00Z",
  "tipo_service": "Cambio de aceite",
  "observaciones": "Revisar frenos"
}
```

#### PATCH /api/v1/appointments/:id/status
Actualiza estado del turno (admin).

**Request:**
```json
{
  "status": "confirmed"
}
```

---

### Services (Historial)

#### GET /api/v1/vehicles/:id/services
Obtiene historial de services de un vehículo.

**Response:**
```json
{
  "services": [
    {
      "id": 1,
      "fecha": "2026-03-01T10:00:00Z",
      "km": 40000,
      "tipo_aceite": "sintetico",
      "marca_aceite": "Mobil 1",
      "productos": "Filtro de aceite, Filtro de aire",
      "observaciones": "Todo ok",
      "proximo_service_km": 50000
    }
  ]
}
```

#### POST /api/v1/services
Registra un service completado (admin).

**Request:**
```json
{
  "vehicle_id": 1,
  "appointment_id": 1,
  "km": 45000,
  "tipo_aceite": "sintetico",
  "marca_aceite": "Mobil 1",
  "productos": "Filtro de aceite",
  "observaciones": "Service completo"
}
```

#### GET /api/v1/vehicles/:id/report
Reporte completo del vehículo (KEY FEATURE).

**Response:**
```json
{
  "vehicle": { "id": 1, "marca": "Toyota", "km_actual": 45000 },
  "status": "ok",
  "ultimo_service": { "fecha": "2026-03-01", "km": 40000 },
  "proximo_service_km": 50000,
  "services_count": 5,
  "historial": []
}
```

---

## Códigos de Error

- `400` - Bad Request (validación)
- `401` - Unauthorized (sin token o inválido)
- `403` - Forbidden (sin permisos)
- `404` - Not Found
- `409` - Conflict (turno solapado)
- `500` - Internal Server Error
