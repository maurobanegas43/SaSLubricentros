# Base de Datos

## Modelo de Datos

### Entidades Principales

#### Users
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Vehicles
```sql
CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    marca VARCHAR(100) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    anio INT NOT NULL,
    motor VARCHAR(100),
    km_actual INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Appointments
```sql
CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_id INT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    fecha TIMESTAMP NOT NULL,
    tipo_service VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled'))
);
```

#### Services (Historial - Inmutable)
```sql
CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    appointment_id INT REFERENCES appointments(id),
    fecha TIMESTAMP NOT NULL,
    km INT NOT NULL,
    tipo_aceite VARCHAR(50) NOT NULL,
    marca_aceite VARCHAR(100),
    productos TEXT,
    observaciones TEXT,
    proximo_service_km INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (tipo_aceite IN ('mineral', 'semi', 'sintetico'))
);
```

## Relaciones

- User → Vehicles: 1:N (un usuario tiene múltiples vehículos)
- User → Appointments: 1:N (un usuario tiene múltiples turnos)
- Vehicle → Appointments: 1:N (un vehículo tiene múltiples turnos)
- Vehicle → Services: 1:N (un vehículo tiene múltiples services)
- Appointment → Service: 1:1 (un turno genera un service)

## Índices

```sql
CREATE INDEX idx_vehicles_user ON vehicles(user_id);
CREATE INDEX idx_appointments_user ON appointments(user_id);
CREATE INDEX idx_appointments_fecha ON appointments(fecha);
CREATE INDEX idx_services_vehicle ON services(vehicle_id);
CREATE INDEX idx_services_fecha ON services(fecha);
```

## Lógica de Negocio

### Cálculo de Próximo Service
- Mineral: km_actual + 5000
- Semi: km_actual + 7000
- Sintético: km_actual + 10000

### Estado del Vehículo (Calculado)
- `ok`: km_actual < proximo_service_km - 500
- `maintenance_due`: km_actual >= proximo_service_km - 500
- `critical`: km_actual >= proximo_service_km

## Migraciones

Las migraciones están en `/backend/migrations/` y se ejecutan en orden numérico.

## Backup y Recuperación

- Backups diarios automáticos de PostgreSQL
- Retención de 30 días
- Procedimiento de restore documentado en ops/
