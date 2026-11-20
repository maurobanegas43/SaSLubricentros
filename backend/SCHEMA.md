# Lubricentros — Database Schema Reference

> MariaDB 10.6+ | utf8mb4 | InnoDB

## Table Relationships

```
users (1) ──────< (N) vehicles
  │                    │
  │                    ├────< (N) appointments
  │                    │         │
  │                    │         └────< (1) service_records
  │                    │                    │
  │                    │                    ├────< (N) service_addendums
  │                    │                    │
  │                    │                    └────< (N) service_parts_used
  │                    │                              │
  │                    │                              └───> (1) products
  │                    │
  │                    └────< (N) ownership_transfers
  │                              │
  │                              └───> users (from_user, to_user, initiated_by)
  │
  ├────< (N) refresh_tokens
  │
  ├────< (N) attachments (entity_type: vehicle | service_record | appointment)
  │
  └────< (N) audit_log
```

## Tables

### 1. `users`
System users — both customers and admins.

| Column          | Type              | Notes                           |
|-----------------|-------------------|---------------------------------|
| id              | INT UNSIGNED AI   | Primary key                     |
| email           | VARCHAR(255)      | UNIQUE, NOT NULL                |
| password_hash   | VARCHAR(255)      | bcrypt hash, NOT NULL           |
| name            | VARCHAR(255)      | NOT NULL                        |
| phone           | VARCHAR(20)       | Nullable                        |
| role            | ENUM              | 'customer' \| 'admin'           |
| is_active       | TINYINT(1)        | 1=active, 0=deactivated         |
| created_at      | TIMESTAMP         | Auto-set                        |
| updated_at      | TIMESTAMP         | Auto-updated                    |

**Relations:** One-to-many with vehicles, appointments, refresh_tokens, attachments, audit_log.

---

### 2. `vehicles`
Registered vehicles owned by users.

| Column     | Type              | Notes                      |
|------------|-------------------|----------------------------|
| id         | INT UNSIGNED AI   | Primary key                |
| user_id    | INT UNSIGNED      | FK → users(id) CASCADE     |
| patente    | VARCHAR(10)       | Argentine plate format     |
| marca      | VARCHAR(100)      | NOT NULL                   |
| modelo     | VARCHAR(100)      | NOT NULL                   |
| anio       | SMALLINT          | NOT NULL                   |
| motor      | VARCHAR(100)      | Nullable                   |
| km_actual  | INT UNSIGNED      | Default 0                  |
| color      | VARCHAR(50)       | Nullable                   |
| created_at | TIMESTAMP         | Auto-set                   |
| updated_at | TIMESTAMP         | Auto-updated               |

**Relations:** Belongs to user. One-to-many with appointments, service_records, ownership_transfers.

---

### 3. `ownership_transfers`
Audit trail of vehicle ownership changes.

| Column         | Type              | Notes                          |
|----------------|-------------------|--------------------------------|
| id             | INT UNSIGNED AI   | Primary key                    |
| vehicle_id     | INT UNSIGNED      | FK → vehicles(id) CASCADE      |
| from_user_id   | INT UNSIGNED      | FK → users(id) SET NULL        |
| to_user_id     | INT UNSIGNED      | FK → users(id) CASCADE         |
| transferred_at | TIMESTAMP         | Auto-set                       |
| reason         | VARCHAR(255)      | Nullable                       |
| initiated_by   | INT UNSIGNED      | FK → users(id) SET NULL        |
| status         | ENUM              | requested \| completed \| rejected |
| notes          | TEXT              | Nullable                       |
| created_at     | TIMESTAMP         | Auto-set                       |

---

### 4. `appointments`
Scheduled service appointments.

| Column       | Type              | Notes                          |
|--------------|-------------------|--------------------------------|
| id           | INT UNSIGNED AI   | Primary key                    |
| user_id      | INT UNSIGNED      | FK → users(id) CASCADE         |
| vehicle_id   | INT UNSIGNED      | FK → vehicles(id) CASCADE      |
| fecha        | DATETIME          | Appointment date/time          |
| slot_end     | DATETIME          | Estimated end time             |
| tipo_service | ENUM              | cambio_aceite \| alineacion \| mecanica_luces \| revision_general \| otro |
| status       | ENUM              | pending \| confirmed \| in_progress \| completed \| cancelled \| no_show |
| observaciones| TEXT              | Nullable                       |
| created_at   | TIMESTAMP         | Auto-set                       |
| updated_at   | TIMESTAMP         | Auto-updated                   |

**Relations:** Belongs to user and vehicle. One-to-one (optional) with service_records.

---

### 5. `service_records`
Immutable history of completed services.

| Column             | Type              | Notes                          |
|--------------------|-------------------|--------------------------------|
| id                 | INT UNSIGNED AI   | Primary key                    |
| vehicle_id         | INT UNSIGNED      | FK → vehicles(id) CASCADE      |
| appointment_id     | INT UNSIGNED      | FK → appointments(id) SET NULL |
| fecha              | DATETIME          | Service date                   |
| km                 | INT UNSIGNED      | Odometer reading               |
| tipo_aceite        | ENUM              | mineral \| semi_sintetico \| sintetico |
| marca_aceite       | VARCHAR(100)      | Nullable                       |
| costo_total        | DECIMAL(10,2)     | Nullable                       |
| observaciones      | TEXT              | Nullable                       |
| proximo_service_km | INT UNSIGNED      | Nullable                       |
| created_by         | INT UNSIGNED      | FK → users(id) RESTRICT        |
| created_at         | TIMESTAMP         | Auto-set                       |

**Relations:** Belongs to vehicle. One-to-many with service_addendums, service_parts_used.

---

### 6. `service_addendums`
Corrections appended to immutable service records (never modify the original).

| Column     | Type              | Notes                          |
|------------|-------------------|--------------------------------|
| id         | INT UNSIGNED AI   | Primary key                    |
| service_id | INT UNSIGNED      | FK → service_records(id) CASCADE |
| field_name | VARCHAR(100)      | Corrected field name           |
| old_value  | TEXT              | Nullable                       |
| new_value  | TEXT              | NOT NULL                       |
| reason     | TEXT              | NOT NULL                       |
| created_by | INT UNSIGNED      | FK → users(id) RESTRICT        |
| created_at | TIMESTAMP         | Auto-set                       |

---

### 7. `products`
Inventory of products/supplies.

| Column       | Type              | Notes                          |
|--------------|-------------------|--------------------------------|
| id           | INT UNSIGNED AI   | Primary key                    |
| sku          | VARCHAR(50)       | UNIQUE, NOT NULL               |
| nombre       | VARCHAR(255)      | NOT NULL                       |
| categoria    | ENUM              | aceite \| filtro \| frenos \| neumaticos \| bateria \| aditivo \| otro |
| descripcion  | TEXT              | Nullable                       |
| precio       | DECIMAL(10,2)     | NOT NULL                       |
| stock_actual | INT               | NOT NULL, default 0            |
| stock_minimo | INT               | NOT NULL, default 5            |
| is_active    | TINYINT(1)        | Default 1                      |
| created_at   | TIMESTAMP         | Auto-set                       |
| updated_at   | TIMESTAMP         | Auto-updated                   |

**Relations:** One-to-many with service_parts_used.

---

### 8. `service_parts_used`
Products consumed during a service (join table).

| Column         | Type              | Notes                          |
|----------------|-------------------|--------------------------------|
| id             | INT UNSIGNED AI   | Primary key                    |
| service_id     | INT UNSIGNED      | FK → service_records(id) CASCADE |
| product_id     | INT UNSIGNED      | FK → products(id) RESTRICT     |
| cantidad       | INT UNSIGNED      | NOT NULL                       |
| costo_unitario | DECIMAL(10,2)     | NOT NULL                       |

---

### 9. `attachments`
Images and files attached to entities (polymorphic).

| Column      | Type              | Notes                          |
|-------------|-------------------|--------------------------------|
| id          | INT UNSIGNED AI   | Primary key                    |
| entity_type | ENUM              | vehicle \| service_record \| appointment |
| entity_id   | INT UNSIGNED      | FK target ID                   |
| file_name   | VARCHAR(255)      | NOT NULL                       |
| file_path   | VARCHAR(500)      | NOT NULL                       |
| mime_type   | VARCHAR(100)      | NOT NULL                       |
| file_size   | INT UNSIGNED      | NOT NULL                       |
| uploaded_by | INT UNSIGNED      | FK → users(id) CASCADE         |
| created_at  | TIMESTAMP         | Auto-set                       |

---

### 10. `refresh_tokens`
JWT refresh token storage (hashed).

| Column     | Type              | Notes                          |
|------------|-------------------|--------------------------------|
| id         | INT UNSIGNED AI   | Primary key                    |
| user_id    | INT UNSIGNED      | FK → users(id) CASCADE         |
| token_hash | VARCHAR(255)      | SHA-256 of actual token, UNIQUE |
| expires_at | DATETIME          | NOT NULL                       |
| created_at | TIMESTAMP         | Auto-set                       |
| revoked_at | TIMESTAMP         | Nullable (NULL = active)       |
| ip_address | VARCHAR(45)       | IPv4 or IPv6                   |
| user_agent | TEXT              | Nullable                       |

---

### 11. `audit_log`
General audit trail for data changes.

| Column     | Type              | Notes                          |
|------------|-------------------|--------------------------------|
| id         | INT UNSIGNED AI   | Primary key                    |
| table_name | VARCHAR(100)      | NOT NULL                       |
| record_id  | INT UNSIGNED      | NOT NULL                       |
| action     | ENUM              | INSERT \| UPDATE \| DELETE     |
| old_data   | JSON              | Nullable                       |
| new_data   | JSON              | Nullable                       |
| changed_by | INT UNSIGNED      | FK → users(id) SET NULL        |
| changed_at | TIMESTAMP         | Auto-set                       |
| ip_address | VARCHAR(45)       | Nullable                       |
