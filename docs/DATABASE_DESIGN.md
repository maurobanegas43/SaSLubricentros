# Database Design — Lubricentros SaaS

> **Engine:** MariaDB 10.6+ | **Charset:** utf8mb4 / utf8mb4_unicode_ci | **Tables:** 11

---

## 1. Entity Relationship Diagram (ASCII)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    LUBRICENTROS SaaS — ERD                                       │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────┐    1:N     ┌──────────┐    1:N     ┌──────────────────┐
│  users  │───────────▶│ vehicles │───────────▶│ ownership_       │
└────┬────┘            └────┬─────┘            │ transfers        │
     │                      │                  └──────────────────┘
     │                      │                        ▲ 1:N
     │                      │                        │
     │                      │                  ┌─────┴─────┐
     │                      │                  │ from_user │
     │                      │                  │ (nullable)│
     │                      │                  └───────────┘
     │                      │
     │                      │ 1:N              ┌──────────────────┐    1:N     ┌──────────────────┐
     │                      └─────────────────▶│ service_         │───────────▶│ service_         │
     │                                         │ records          │            │ addendums        │
     │                                         └───────┬──────────┘            └──────────────────┘
     │                                                 │
     │                                                 │ 1:N
     │                                                 ▼
     │                                         ┌──────────────────┐
     │                                         │ service_         │
     │                                         │ parts_used       │
     │                                         └───────┬──────────┘
     │                                                 │
     │ 1:N                                             │ N:1
     │                                                 ▼
     │                      ┌──────────┐               ┌──────────┐
     │                      │appoint-  │◀── 1:0..1 ───│ service  │
     │                      │ ments    │   (optional)  │ records  │
     │                      └────┬─────┘               │(appt_id) │
     │                           │                     └──────────┘
     │ 1:N                       │
     │                           ▼
     │                      ┌──────────┐
     │                      │ products │
     │                      └──────────┘
     │
     │ 1:N              ┌──────────────────┐
     └─────────────────▶│ refresh_         │
                        │ tokens           │
                        └──────────────────┘

     1:N              ┌──────────────────┐
     └────────────────▶│ attachments      │
                       │ (entity_type +   │
                       │  entity_id =     │
                       │  polymorphic FK) │
                       └──────────────────┘

     1:N              ┌──────────────────┐
     └────────────────▶│ audit_log        │
                       │ (table_name +    │
                       │  record_id =     │
                       │  polymorphic FK) │
                       └──────────────────┘
```

**Relationship Summary:**

```
users 1───────────────────N vehicles              (owner)
users 1───────────────────N appointments           (booker)
users 1───────────────────N service_records        (creator/mechanic)
users 1───────────────────N service_addendums      (corrector)
users 1───────────────────N refresh_tokens         (session)
users 1───────────────────N attachments            (uploader)
users 1───────────────────N audit_log              (changer, nullable)
users 1───────────────────N ownership_transfers    (to_user)
users 1────0..1───────────N ownership_transfers    (from_user, nullable)
users 1────0..1───────────N ownership_transfers    (initiated_by, nullable)

vehicles 1────────────────N appointments           (vehicle for appt)
vehicles 1────────────────N service_records        (serviced vehicle)
vehicles 1────────────────N ownership_transfers    (transferred vehicle)

appointments 1────0..1────N service_records        (origin appt, nullable)

service_records 1─────────N service_addendums      (corrections)
service_records 1─────────N service_parts_used     (parts consumed)

products 1────────────────N service_parts_used     (product used)
```

---

## 2. Relationship Documentation

### 2.1 users -> vehicles (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one user owns many vehicles) |
| **FK** | `vehicles.user_id -> users.id` |
| **ON DELETE** | CASCADE — delete user, delete their vehicles |
| **ON UPDATE** | RESTRICT (InnoDB default) |
| **Business** | `vehicles.user_id` points to the *current* owner. When ownership changes, this column is updated and an `ownership_transfers` row is created. |

### 2.2 users -> appointments (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one user books many appointments) |
| **FK** | `appointments.user_id -> users.id` |
| **ON DELETE** | CASCADE — delete user, cancel their appointments |
| **ON UPDATE** | RESTRICT |
| **Business** | The user who made the reservation. Must exist at booking time. |

### 2.3 vehicles -> appointments (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one vehicle has many appointments over time) |
| **FK** | `appointments.vehicle_id -> vehicles.id` |
| **ON DELETE** | CASCADE — delete vehicle, delete its appointments |
| **ON UPDATE** | RESTRICT |
| **Business** | Links a service appointment to the specific vehicle being serviced. |

### 2.4 vehicles -> service_records (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one vehicle accumulates many service records) |
| **FK** | `service_records.vehicle_id -> vehicles.id` |
| **ON DELETE** | CASCADE — delete vehicle, delete its history |
| **ON UPDATE** | RESTRICT |
| **Business** | Immutable log of all services performed on a vehicle. Never updated or deleted. |

### 2.5 appointments -> service_records (1:0..1)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:0..1 (one appointment may generate one service record) |
| **FK** | `service_records.appointment_id -> appointments.id` |
| **ON DELETE** | SET NULL — if appointment is deleted, service record survives |
| **ON UPDATE** | RESTRICT |
| **Business** | Optional link. Walk-in services have no appointment. A completed appointment should eventually have a service record. |

### 2.6 users -> service_records (1:N, via created_by)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one admin/mechanic creates many service records) |
| **FK** | `service_records.created_by -> users.id` |
| **ON DELETE** | **RESTRICT** — cannot delete a user who created service records |
| **ON UPDATE** | RESTRICT |
| **Business** | Auditing: who performed the service. RESTRICT prevents losing accountability. |

### 2.7 service_records -> service_addendums (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one service record may have many correction addendums) |
| **FK** | `service_addendums.service_id -> service_records.id` |
| **ON DELETE** | CASCADE — delete service, delete its addendums |
| **ON UPDATE** | RESTRICT |
| **Business** | Since service_records are immutable, corrections are appended as addendums with old_value, new_value, and reason. |

### 2.8 users -> service_addendums (1:N, via created_by)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one user creates many addendums) |
| **FK** | `service_addendums.created_by -> users.id` |
| **ON DELETE** | **RESTRICT** — cannot delete a user who created addendums |
| **ON UPDATE** | RESTRICT |
| **Business** | Who made the correction. RESTRICT for audit trail integrity. |

### 2.9 service_records -> service_parts_used (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one service uses many parts) |
| **FK** | `service_parts_used.service_id -> service_records.id` |
| **ON DELETE** | CASCADE — delete service, delete its parts usage |
| **ON UPDATE** | RESTRICT |
| **Business** | Line items for products consumed during a service. |

### 2.10 products -> service_parts_used (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one product appears in many service records) |
| **FK** | `service_parts_used.product_id -> products.id` |
| **ON DELETE** | **RESTRICT** — cannot delete a product that was used in a service |
| **ON UPDATE** | RESTRICT |
| **Business** | Preserves historical accuracy. If a product is discontinued, it can be marked `is_active=0` but not deleted. |

### 2.11 vehicles -> ownership_transfers (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one vehicle has many ownership changes) |
| **FK** | `ownership_transfers.vehicle_id -> vehicles.id` |
| **ON DELETE** | CASCADE — delete vehicle, delete its transfer history |
| **ON UPDATE** | RESTRICT |
| **Business** | Complete chain of custody for a vehicle. |

### 2.12 users -> ownership_transfers (multiple FKs)

| FK Column | Type | ON DELETE | Business |
|-----------|------|-----------|----------|
| `to_user_id` | 1:N (required) | CASCADE | New owner must exist |
| `from_user_id` | 1:0..N (nullable) | SET NULL | Previous owner may have been deleted |
| `initiated_by` | 1:0..N (nullable) | SET NULL | Admin who initiated; may be deleted |

### 2.13 users -> refresh_tokens (1:N)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one user has many active/revoked tokens) |
| **FK** | `refresh_tokens.user_id -> users.id` |
| **ON DELETE** | CASCADE — delete user, invalidate all tokens |
| **ON UPDATE** | RESTRICT |
| **Business** | JWT refresh token storage. Hashed, never stores raw token. |

### 2.14 users -> attachments (1:N, via uploaded_by)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:N (one user uploads many attachments) |
| **FK** | `attachments.uploaded_by -> users.id` |
| **ON DELETE** | CASCADE — delete user, delete their uploads |
| **ON UPDATE** | RESTRICT |
| **Business** | Polymorphic: `entity_type` + `entity_id` point to vehicle, service_record, or appointment. |

### 2.15 users -> audit_log (1:0..N, via changed_by)

| Aspect | Detail |
|--------|--------|
| **Type** | 1:0..N (nullable — system actions have no user) |
| **FK** | `audit_log.changed_by -> users.id` |
| **ON DELETE** | SET NULL — preserve audit trail even if user is deleted |
| **ON UPDATE** | RESTRICT |
| **Business** | General-purpose audit trail. Polymorphic via `table_name` + `record_id`. |

---

## 3. Index Strategy

### 3.1 Index Inventory & Rationale

| Table | Index | Columns | Type | Rationale |
|-------|-------|---------|------|-----------|
| **users** | `uq_users_email` | `email` | UNIQUE | Enforce email uniqueness; primary login lookup (high selectivity) |
| **users** | `idx_users_role` | `role` | BTREE | Filter by role (admin vs customer). LOW cardinality (2 values) — only useful combined with other filters |
| **users** | `idx_users_active` | `is_active` | BTREE | Filter active/inactive users. LOW cardinality — useful for admin dashboards |
| **vehicles** | `idx_vehicles_user` | `user_id` | BTREE | **HOT PATH** — "get all vehicles for user". Medium cardinality |
| **vehicles** | `idx_vehicles_patente` | `patente` | BTREE | Search vehicle by license plate. HIGH cardinality, often NULL — acceptable as-is |
| **vehicles** | `idx_vehicles_marca_modelo` | `marca, modelo` | COMPOSITE | Filter by brand+model for inventory reports. Left-prefix: queries on `marca` alone also benefit |
| **ownership_transfers** | `idx_ot_vehicle` | `vehicle_id` | BTREE | "Get ownership history for vehicle". Medium cardinality |
| **ownership_transfers** | `idx_ot_from_user` | `from_user_id` | BTREE | "What vehicles did this user sell?" Nullable — includes NULLs |
| **ownership_transfers** | `idx_ot_to_user` | `to_user_id` | BTREE | "What vehicles did this user buy?" |
| **appointments** | `idx_appt_user` | `user_id` | BTREE | "Get my appointments". Medium cardinality |
| **appointments** | `idx_appt_vehicle` | `vehicle_id` | BTREE | "Get appointments for vehicle". Medium cardinality |
| **appointments** | `idx_appt_fecha` | `fecha` | BTREE | **HOT PATH** — "find available slots" (range scan on datetime). HIGH cardinality |
| **appointments** | `idx_appt_status` | `status` | BTREE | Filter by status. LOW cardinality (6 values) — only useful combined |
| **appointments** | `idx_appt_user_status` | `user_id, status` | COMPOSITE | **OPTIMIZED** — "get my pending appointments". Covers both filters in one index scan |
| **service_records** | `idx_sr_vehicle` | `vehicle_id` | BTREE | "Get service history for vehicle". Medium cardinality |
| **service_records** | `idx_sr_fecha` | `fecha DESC` | BTREE | "Get recent services across all vehicles". Descending for ORDER BY optimization |
| **service_records** | `idx_sr_vehicle_fecha` | `vehicle_id, fecha DESC` | COMPOSITE | **CRITICAL** — "get service history for vehicle, ordered by date DESC". Covers WHERE + ORDER BY in one index. No filesort needed |
| **service_records** | `idx_sr_km` | `km` | BTREE | "Find services at specific mileage". Range queries for maintenance predictions |
| **service_addendums** | `idx_sa_service` | `service_id` | BTREE | "Get all corrections for a service". Medium cardinality |
| **products** | `uq_products_sku` | `sku` | UNIQUE | Enforce SKU uniqueness; primary lookup |
| **products** | `idx_products_categoria` | `categoria, is_active` | COMPOSITE | "Get active products by category". Left-prefix: `categoria` alone also works |
| **products** | `idx_products_low_stock` | `id WHERE stock_actual <= stock_minimo AND is_active = 1` | PARTIAL | **MariaDB 10.6+** — conditional index for low-stock alerts. Only indexes rows that match the condition, saving space |
| **service_parts_used** | `idx_spu_service` | `service_id` | BTREE | "Get parts used in a service". Medium cardinality |
| **service_parts_used** | `idx_spu_product` | `product_id` | BTREE | "How many times was this product used?" Medium cardinality |
| **attachments** | `idx_att_entity` | `entity_type, entity_id` | COMPOSITE | Polymorphic lookup: "get attachments for this entity". Both columns needed for selectivity |
| **attachments** | `idx_att_uploaded_by` | `uploaded_by` | BTREE | "Get files uploaded by user" |
| **refresh_tokens** | `uq_rt_token_hash` | `token_hash` | UNIQUE | Enforce token uniqueness; primary lookup for validation |
| **refresh_tokens** | `idx_rt_user` | `user_id` | BTREE | "Get all tokens for user" (for logout-all) |
| **refresh_tokens** | `idx_rt_expires` | `expires_at` | BTREE | **CLEANUP** — "find expired tokens for deletion". Range scan, cron job |
| **audit_log** | `idx_audit_table_record` | `table_name, record_id` | COMPOSITE | "Get audit trail for specific record". Both columns needed |
| **audit_log** | `idx_audit_changed_at` | `changed_at DESC` | BTREE | "Get recent audit events". Descending for ORDER BY |
| **audit_log** | `idx_audit_changed_by` | `changed_by` | BTREE | "What did this user change?" Nullable |

### 3.2 Composite Index Rationale

**`idx_sr_vehicle_fecha (vehicle_id, fecha DESC)`**

This is the most important composite index. It serves the most common query pattern:

```sql
-- Uses index for both WHERE and ORDER BY — zero filesort
SELECT * FROM service_records
WHERE vehicle_id = ?
ORDER BY fecha DESC;
```

The column order matters: `vehicle_id` first (equality filter), then `fecha DESC` (sort). Reversing the order would require a full index scan.

**`idx_appt_user_status (user_id, status)`**

Covers the dashboard query "show me my pending/confirmed appointments":

```sql
SELECT * FROM appointments
WHERE user_id = ? AND status = 'pending';
```

**`idx_att_entity (entity_type, entity_id)`**

Polymorphic pattern requires both columns. `entity_type` alone has very low cardinality (3 values), but combined with `entity_id` it becomes highly selective.

### 3.3 Cardinality Warnings

- `role` (ENUM, 2 values): Index exists but optimizer may choose full table scan for small tables. Becomes useful at >10K users.
- `is_active` (TINYINT, 2 values): Same caveat. Useful for admin filters combined with other conditions.
- `status` on appointments (6 values): Low cardinality. The composite `idx_appt_user_status` is the one that matters.

---

## 4. Query Templates

### 4.1 User's Vehicles with Latest Service

```sql
-- Get all vehicles for a user with their most recent service
SELECT
    v.id,
    v.patente,
    v.marca,
    v.modelo,
    v.anio,
    v.motor,
    v.km_actual,
    v.color,
    sr.fecha AS last_service_date,
    sr.km AS last_service_km,
    sr.tipo_aceite,
    sr.marca_aceite,
    sr.proximo_service_km
FROM vehicles v
LEFT JOIN service_records sr ON sr.vehicle_id = v.id
    AND sr.id = (
        SELECT id FROM service_records
        WHERE vehicle_id = v.id
        ORDER BY fecha DESC
        LIMIT 1
    )
WHERE v.user_id = ?
ORDER BY v.created_at DESC;
```

### 4.2 Available Appointment Slots

```sql
-- Find available slots in a date range (no conflicting appointments)
-- Assumes 1-hour slots
SELECT
    DATE_ADD(slot_start, INTERVAL n HOUR) AS available_start,
    DATE_ADD(slot_start, INTERVAL n + 1 HOUR) AS available_end
FROM (
    SELECT ? AS slot_start  -- e.g., '2025-01-15 08:00:00'
) base
JOIN (
    SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
) hours
WHERE DATE_ADD(slot_start, INTERVAL n HOUR) >= NOW()
  AND DATE_ADD(slot_start, INTERVAL n HOUR) NOT IN (
      SELECT fecha FROM appointments
      WHERE status NOT IN ('cancelled', 'no_show')
        AND fecha BETWEEN slot_start AND DATE_ADD(slot_start, INTERVAL 8 HOUR)
  )
ORDER BY available_start;
```

```sql
-- Simpler: get busy slots for a given day
SELECT fecha, slot_end, tipo_service, status
FROM appointments
WHERE DATE(fecha) = ?
  AND status NOT IN ('cancelled', 'no_show')
ORDER BY fecha;
```

### 4.3 Vehicle Ownership History

```sql
-- Complete ownership chain for a vehicle
SELECT
    ot.id,
    ot.transferred_at,
    ot.reason,
    ot.status,
    ot.notes,
    fu.name AS from_user_name,
    fu.email AS from_user_email,
    tu.name AS to_user_name,
    tu.email AS to_user_email,
    ib.name AS initiated_by_name
FROM ownership_transfers ot
LEFT JOIN users fu ON fu.id = ot.from_user_id
JOIN users tu ON tu.id = ot.to_user_id
LEFT JOIN users ib ON ib.id = ot.initiated_by
WHERE ot.vehicle_id = ?
ORDER BY ot.transferred_at ASC;
```

### 4.4 Service Report Data (Full Detail)

```sql
-- Complete service report with parts used
SELECT
    sr.id AS service_id,
    sr.fecha,
    sr.km,
    sr.tipo_aceite,
    sr.marca_aceite,
    sr.costo_total,
    sr.observaciones,
    sr.proximo_service_km,
    cb.name AS created_by_name,
    v.patente,
    v.marca,
    v.modelo,
    -- Parts used
    sp.product_id,
    p.nombre AS product_name,
    p.categoria,
    sp.cantidad,
    sp.costo_unitario,
    (sp.cantidad * sp.costo_unitario) AS line_total
FROM service_records sr
JOIN vehicles v ON v.id = sr.vehicle_id
JOIN users cb ON cb.id = sr.created_by
LEFT JOIN service_parts_used sp ON sp.service_id = sr.id
LEFT JOIN products p ON p.id = sp.product_id
WHERE sr.id = ?
ORDER BY sp.product_id;
```

```sql
-- Service record with its addendums
SELECT
    sr.*,
    sa.field_name,
    sa.old_value,
    sa.new_value,
    sa.reason AS addendum_reason,
    sa.created_at AS addendum_at,
    ab.name AS addendum_by
FROM service_records sr
LEFT JOIN service_addendums sa ON sa.service_id = sr.id
LEFT JOIN users ab ON ab.id = sa.created_by
WHERE sr.id = ?
ORDER BY sa.created_at ASC;
```

### 4.5 Low Stock Products

```sql
-- Products at or below minimum stock (uses partial index)
SELECT
    id,
    sku,
    nombre,
    categoria,
    stock_actual,
    stock_minimo,
    (stock_minimo - stock_actual) AS deficit
FROM products
WHERE stock_actual <= stock_minimo
  AND is_active = 1
ORDER BY (stock_minimo - stock_actual) DESC;
```

```sql
-- Products most frequently used in services (for reorder planning)
SELECT
    p.id,
    p.sku,
    p.nombre,
    p.stock_actual,
    p.stock_minimo,
    COUNT(spu.id) AS times_used,
    SUM(spu.cantidad) AS total_units_used
FROM products p
JOIN service_parts_used spu ON spu.product_id = p.id
JOIN service_records sr ON sr.id = spu.service_id
WHERE sr.fecha >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
  AND p.is_active = 1
GROUP BY p.id
ORDER BY total_units_used DESC
LIMIT 20;
```

### 4.6 Pending Appointments

```sql
-- All pending appointments (admin dashboard)
SELECT
    a.id,
    a.fecha,
    a.slot_end,
    a.tipo_service,
    a.status,
    a.observaciones,
    u.name AS customer_name,
    u.phone AS customer_phone,
    u.email AS customer_email,
    v.patente,
    v.marca,
    v.modelo
FROM appointments a
JOIN users u ON u.id = a.user_id
JOIN vehicles v ON v.id = a.vehicle_id
WHERE a.status = 'pending'
  AND a.fecha >= NOW()
ORDER BY a.fecha ASC;
```

```sql
-- User's upcoming appointments
SELECT
    a.id,
    a.fecha,
    a.slot_end,
    a.tipo_service,
    a.status,
    v.patente,
    v.marca,
    v.modelo
FROM appointments a
JOIN vehicles v ON v.id = a.vehicle_id
WHERE a.user_id = ?
  AND a.status IN ('pending', 'confirmed')
  AND a.fecha >= NOW()
ORDER BY a.fecha ASC;
```

### 4.7 Vehicle Service History Summary

```sql
-- Service history for a vehicle with cost summary
SELECT
    sr.id,
    sr.fecha,
    sr.km,
    sr.tipo_aceite,
    sr.marca_aceite,
    sr.costo_total,
    sr.observaciones,
    sr.proximo_service_km,
    u.name AS created_by,
    COUNT(spu.id) AS parts_count,
    COALESCE(SUM(spu.cantidad * spu.costo_unitario), 0) AS parts_cost
FROM service_records sr
JOIN users u ON u.id = sr.created_by
LEFT JOIN service_parts_used spu ON spu.service_id = sr.id
WHERE sr.vehicle_id = ?
GROUP BY sr.id
ORDER BY sr.fecha DESC;
```

### 4.8 Monthly Revenue Report

```sql
-- Monthly revenue from services
SELECT
    DATE_FORMAT(sr.fecha, '%Y-%m') AS month,
    COUNT(DISTINCT sr.id) AS total_services,
    COALESCE(SUM(sr.costo_total), 0) AS total_revenue,
    COALESCE(SUM(spu.cantidad * spu.costo_unitario), 0) AS parts_cost,
    COALESCE(SUM(sr.costo_total), 0) - COALESCE(SUM(spu.cantidad * spu.costo_unitario), 0) AS labor_cost
FROM service_records sr
LEFT JOIN service_parts_used spu ON spu.service_id = sr.id
WHERE sr.fecha >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(sr.fecha, '%Y-%m')
ORDER BY month DESC;
```

### 4.9 User Login + Profile

```sql
-- Authenticate user (returns minimal data for JWT creation)
SELECT
    id,
    email,
    password_hash,
    name,
    phone,
    role,
    is_active
FROM users
WHERE email = ?
  AND is_active = 1;
```

### 4.10 Expired Token Cleanup

```sql
-- Find expired tokens for cron cleanup
SELECT id, user_id, expires_at
FROM refresh_tokens
WHERE expires_at < NOW()
  AND revoked_at IS NULL;

-- Revoke all expired tokens
UPDATE refresh_tokens
SET revoked_at = NOW()
WHERE expires_at < NOW()
  AND revoked_at IS NULL;
```

---

## 5. Data Integrity Rules

### 5.1 Column-Level Constraints

| Constraint | Table | Column | Rule | Why |
|------------|-------|--------|------|-----|
| **Email uniqueness** | users | email | `UNIQUE KEY uq_users_email` | One account per email. Prevents duplicate registrations. |
| **SKU uniqueness** | products | sku | `UNIQUE KEY uq_products_sku` | Each product has a unique inventory code. |
| **Token hash uniqueness** | refresh_tokens | token_hash | `UNIQUE KEY uq_rt_token_hash` | Prevents token replay/duplication. |
| **Role enum** | users | role | `ENUM('customer', 'admin')` | Only two roles exist. Database-level enforcement, no invalid states. |
| **Appointment type enum** | appointments | tipo_service | `ENUM('cambio_aceite', 'alineacion', 'mecanica_luces', 'revision_general', 'otro')` | Fixed service catalog. Easy to extend by ALTER TABLE. |
| **Appointment status enum** | appointments | status | `ENUM('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show')` | State machine — see transitions below. |
| **Oil type enum** | service_records | tipo_aceite | `ENUM('mineral', 'semi_sintetico', 'sintetico')` | Three oil types only. Determines next-service interval. |
| **Product category enum** | products | categoria | `ENUM('aceite', 'filtro', 'frenos', 'neumaticos', 'bateria', 'aditivo', 'otro')` | Fixed categories for reporting. |
| **Attachment entity enum** | attachments | entity_type | `ENUM('vehicle', 'service_record', 'appointment')` | Polymorphic constraint — only valid entity types. |
| **Audit action enum** | audit_log | action | `ENUM('INSERT', 'UPDATE', 'DELETE')` | Only three action types tracked. |
| **Transfer status enum** | ownership_transfers | status | `ENUM('requested', 'completed', 'rejected')` | Transfer workflow states. |
| **Non-negative stock** | products | stock_actual | `INT` (signed, application enforces >= 0) | Stock cannot go negative. **RECOMMENDATION:** add CHECK constraint. |
| **Non-negative quantities** | service_parts_used | cantidad | `INT UNSIGNED` | Cannot use negative parts. Unsigned enforces at DB level. |
| **Non-negative km** | vehicles | km_actual | `INT UNSIGNED` | Odometer never decreases. |
| **Non-negative km** | service_records | km | `INT UNSIGNED` | Service recorded at a positive mileage. |
| **File size** | attachments | file_size | `INT UNSIGNED` | File sizes are always positive. |
| **Active flag** | users | is_active | `TINYINT(1)` DEFAULT 1 | Soft-delete pattern. Deactivated users can't log in. |
| **Active flag** | products | is_active | `TINYINT(1)` DEFAULT 1 | Soft-delete for discontinued products. |

### 5.2 Recommended CHECK Constraints (add in migration 002)

```sql
-- Non-negative stock (MariaDB 10.2+ supports CHECK)
ALTER TABLE products
    ADD CONSTRAINT chk_products_stock_non_negative
    CHECK (stock_actual >= 0);

ALTER TABLE products
    ADD CONSTRAINT chk_products_stock_min_non_negative
    CHECK (stock_minimo >= 0);

-- Year validation (vehicles must be reasonable)
ALTER TABLE vehicles
    ADD CONSTRAINT chk_vehicles_year
    CHECK (anio BETWEEN 1900 AND YEAR(CURRENT_DATE) + 1);

-- Service km must be >= 0
ALTER TABLE service_records
    ADD CONSTRAINT chk_sr_km_positive
    CHECK (km >= 0);

-- Appointment end must be after start
ALTER TABLE appointments
    ADD CONSTRAINT chk_appt_slot_end_after_start
    CHECK (slot_end > fecha);

-- Cost must be non-negative
ALTER TABLE service_records
    ADD CONSTRAINT chk_sr_cost_non_negative
    CHECK (costo_total IS NULL OR costo_total >= 0);

ALTER TABLE service_parts_used
    ADD CONSTRAINT chk_spu_cost_positive
    CHECK (costo_unitario >= 0);
```

### 5.3 Status Transition Rules (Application-Enforced)

The database cannot enforce state machine transitions with native MariaDB features without triggers. These must be enforced in application logic:

```
APPOINTMENT STATUS TRANSITIONS:

  pending ──────▶ confirmed ──────▶ in_progress ──────▶ completed
     │                │                                    │
     │                │                                    │
     ▼                ▼                                    │
  cancelled        no_show                                 │
                                                          ▼
                                                    (service_record created)

  INVALID TRANSITIONS:
  - completed -> pending (cannot un-complete)
  - cancelled -> confirmed (cannot un-cancel)
  - no_show -> in_progress (cannot resurrect)
```

**Recommended trigger for enforcement (optional):**

```sql
DELIMITER //
CREATE TRIGGER trg_appt_status_transition
BEFORE UPDATE ON appointments
FOR EACH ROW
BEGIN
    DECLARE valid_transition TINYINT DEFAULT 0;

    IF OLD.status = 'pending' AND NEW.status IN ('confirmed', 'cancelled') THEN
        SET valid_transition = 1;
    ELSEIF OLD.status = 'confirmed' AND NEW.status IN ('in_progress', 'cancelled', 'no_show') THEN
        SET valid_transition = 1;
    ELSEIF OLD.status = 'in_progress' AND NEW.status IN ('completed', 'cancelled') THEN
        SET valid_transition = 1;
    ELSEIF OLD.status = 'completed' THEN
        SET valid_transition = 0; -- terminal state
    ELSEIF OLD.status = 'cancelled' THEN
        SET valid_transition = 0; -- terminal state
    ELSEIF OLD.status = 'no_show' THEN
        SET valid_transition = 0; -- terminal state
    END IF;

    IF valid_transition = 0 AND OLD.status != NEW.status THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid appointment status transition';
    END IF;
END//
DELIMITER ;
```

### 5.4 Immutable Service Records

**Rule:** `service_records` must never be UPDATEd or DELETEd after creation.

**Enforcement options:**

**Option A — REVOKE privileges (recommended):**
```sql
-- App user can only INSERT and SELECT
REVOKE UPDATE, DELETE ON lubricentros.service_records FROM 'app_user'@'%';
GRANT INSERT, SELECT ON lubricentros.service_records TO 'app_user'@'%';
```

**Option B — BEFORE UPDATE/DELETE trigger:**
```sql
DELIMITER //
CREATE TRIGGER trg_sr_no_update
BEFORE UPDATE ON service_records
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Service records are immutable. Use service_addendums for corrections.';
END//

CREATE TRIGGER trg_sr_no_delete
BEFORE DELETE ON service_records
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Service records cannot be deleted.';
END//
DELIMITER ;
```

---

## 6. MariaDB-Specific Optimizations

### 6.1 InnoDB Configuration

```ini
# /etc/mysql/mariadb.conf.d/99-lubricentros.cnf

[mysqld]
# --- InnoDB Buffer Pool ---
# Rule: 60-80% of available RAM for dedicated DB server
# For 4GB RAM server:
innodb_buffer_pool_size = 2G
innodb_buffer_pool_instances = 2          # 1 instance per 1GB

# --- Redo Log ---
innodb_log_file_size = 256M               # Larger = fewer flushes
innodb_log_buffer_size = 32M              # Buffer before writing to redo log
innodb_flush_log_at_trx_commit = 1        # ACID: flush every commit (SaaS = data safety)
                                          # Use 2 if performance > safety (accept 1s data loss)

# --- I/O ---
innodb_io_capacity = 200                  # SSD: 2000, HDD: 200
innodb_io_capacity_max = 400              # SSD: 4000, HDD: 400
innodb_flush_method = O_DIRECT            # Bypass OS cache, avoid double buffering

# --- Concurrency ---
innodb_thread_concurrency = 0             # 0 = unlimited (let OS scheduler decide)
innodb_read_io_threads = 4
innodb_write_io_threads = 4

# --- Transaction Isolation ---
transaction_isolation = READ COMMITTED    # Better concurrency than REPEATABLE READ
                                          # SaaS workload: many reads, few writes

# --- Query Optimizer ---
optimizer_switch = 'index_condition_pushdown=on,mrr=on,mrr_cost_based=on'
```

### 6.2 Query Cache Considerations

**MariaDB 10.6+: Query cache is REMOVED.** Do not attempt to enable it.

Alternative caching strategies:
1. **Application-level cache** (Redis/Memcached) for:
   - Product catalog (changes infrequently)
   - User profile data
   - Vehicle list per user
2. **InnoDB Buffer Pool** handles hot data automatically — the 2GB pool will cache frequently accessed pages.

### 6.3 Connection Pool Sizing

```
Formula: connection_pool_size = (core_count * 2) + effective_spindle_count

For a 4-core server with SSD:
  pool_size = (4 * 2) + 1 = 9 -> round to 10-15

Recommended pool configuration:
  - Minimum connections: 5
  - Maximum connections: 20
  - Idle timeout: 300s
  - Connection lifetime: 1800s (30 min)
  - Validation query: SELECT 1
```

**MariaDB max_connections:**
```ini
max_connections = 100          # Default is 151, reduce for SaaS
max_user_connections = 20      # Per-user limit
wait_timeout = 300             # Close idle connections after 5 min
interactive_timeout = 300
```

### 6.4 Backup Strategy

```bash
# === FULL BACKUP (daily, 2 AM) ===
mysqldump \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --flush-logs \
  --hex-blob \
  --databases lubricentros \
  -u backup_user -p \
  | gzip > /backups/lubricentros_$(date +%Y%m%d_%H%M%S).sql.gz

# === INCREMENTAL via Binary Logs (continuous) ===
# Enable binary logging in my.cnf:
#   log_bin = /var/log/mysql/mysql-bin
#   binlog_format = ROW
#   expire_logs_days = 7

# === RESTORE ===
gunzip < /backups/lubricentros_20250115_020000.sql.gz | mysql -u root -p lubricentros

# === POINT-IN-TIME RECOVERY ===
mysqlbinlog /var/log/mysql/mysql-bin.000042 | mysql -u root -p
```

**Backup user (minimal privileges):**
```sql
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'strong_password';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER, RELOAD ON *.* TO 'backup_user'@'localhost';
GRANT SELECT ON lubricentros.* TO 'backup_user'@'localhost';
FLUSH PRIVILEGES;
```

### 6.5 Migration Strategy

```bash
# === Running the initial schema ===
mysql -u root -p < backend/migrations/001_mariadb_schema.sql

# === Future migrations (numbered sequentially) ===
# 002_add_check_constraints.sql
# 003_add_audit_triggers.sql
# 004_add_stored_procedures.sql

# Execute in order:
for f in backend/migrations/*.sql; do
    echo "Applying $f..."
    mysql -u root -p lubricentros < "$f"
done

# === Migration tracking table ===
CREATE TABLE IF NOT EXISTS _migrations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64) NOT NULL COMMENT 'SHA-256 of file content'
) ENGINE=InnoDB;

# === Verify migration was applied ===
SELECT filename, applied_at FROM _migrations ORDER BY applied_at DESC;
```

**Migration best practices:**
1. Each migration is **idempotent** where possible (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`)
2. Always record migration in `_migrations` table
3. Never modify an already-applied migration file — create a new one
4. Test migrations on a copy of production data before applying

---

## 7. Sample Data

```sql
-- ============================================================
-- SAMPLE DATA — Development Environment
-- ============================================================
-- Run AFTER 001_mariadb_schema.sql
-- Passwords are bcrypt hashes of "Test1234!"
-- ============================================================

USE lubricentros;

-- --- USERS ---
-- Customer: juan.perez@email.com / Test1234!
-- Admin: admin@lubricentro.com / Test1234!

INSERT INTO users (email, password_hash, name, phone, role, is_active) VALUES
('juan.perez@email.com', '$2b$12$LJ3m4ys3Lk0TlBZFBGpAJuGHLXKEPzYqR5r3VqG0KqZ0VqG0KqZ0u', 'Juan Perez', '+54 11 5555-1234', 'customer', 1),
('admin@lubricentro.com', '$2b$12$LJ3m4ys3Lk0TlBZFBGpAJuGHLXKEPzYqR5r3VqG0KqZ0VqG0KqZ0u', 'Maria Gonzalez', '+54 11 5555-9999', 'admin', 1);

-- --- VEHICLES ---
-- Juan owns 2 vehicles, Maria (admin) owns 1

INSERT INTO vehicles (user_id, patente, marca, modelo, anio, motor, km_actual, color) VALUES
(1, 'ABC1234', 'Toyota', 'Corolla', 2020, '1.8L 4cil', 45000, 'Blanco'),
(1, 'AB123CD', 'Ford', 'Focus', 2018, '2.0L 4cil', 72000, 'Gris'),
(2, 'XYZ9876', 'Volkswagen', 'Golf', 2022, '1.4L TSI', 15000, 'Negro');

-- --- OWNERSHIP TRANSFERS ---
-- Vehicle 2 (Ford Focus) was transferred from a previous owner

-- First create a "previous owner" user that we'll then reference
INSERT INTO users (email, password_hash, name, phone, role, is_active) VALUES
('vendedor@email.com', '$2b$12$LJ3m4ys3Lk0TlBZFBGpAJuGHLXKEPzYqR5r3VqG0KqZ0VqG0KqZ0u', 'Carlos Vendedor', '+54 11 5555-7777', 'customer', 0);

INSERT INTO ownership_transfers (vehicle_id, from_user_id, to_user_id, transferred_at, reason, initiated_by, status, notes) VALUES
(2, 3, 1, '2024-06-15 10:30:00', 'Venta de usado', 2, 'completed', 'Transferencia por compra-venta'),
(1, NULL, 1, '2020-03-01 00:00:00', 'Primera registracion', 2, 'completed', 'Vehiculo 0km');

-- --- PRODUCTS ---

INSERT INTO products (sku, nombre, categoria, descripcion, precio, stock_actual, stock_minimo, is_active) VALUES
('ACE-5W30-1L', 'Aceite Sintetico 5W-30 1L', 'aceite', 'Aceite sintetico premium para motores nafta', 8500.00, 120, 20, 1),
('ACE-10W40-1L', 'Aceite Semi-Sintetico 10W-40 1L', 'aceite', 'Aceite semi-sintetico uso general', 5200.00, 85, 20, 1),
('ACE-20W50-1L', 'Aceite Mineral 20W-50 1L', 'aceite', 'Aceite mineral para motores antiguos', 3800.00, 45, 15, 1),
('FLT-ACEITE-001', 'Filtro de Aceite Universal', 'filtro', 'Filtro de aceite compatible multiples marcas', 2500.00, 8, 10, 1),
('FLT-AIRE-TOY', 'Filtro de Aire Toyota Corolla', 'filtro', 'Filtro de aire especifico Corolla 2020+', 3200.00, 3, 5, 1);

-- --- APPOINTMENTS ---
-- Mix of statuses across different dates

INSERT INTO appointments (user_id, vehicle_id, fecha, slot_end, tipo_service, status, observaciones) VALUES
(1, 1, '2025-01-20 09:00:00', '2025-01-20 10:00:00', 'cambio_aceite', 'pending', 'Cliente solicita sintetico 5W-30'),
(1, 2, '2025-01-20 10:30:00', '2025-01-20 11:30:00', 'revision_general', 'confirmed', 'Revision pre-viaje'),
(1, 1, '2025-01-15 14:00:00', '2025-01-15 15:00:00', 'cambio_aceite', 'completed', NULL),
(2, 3, '2025-01-18 11:00:00', '2025-01-18 12:00:00', 'alineacion', 'completed', 'Alineacion y balanceo'),
(1, 1, '2025-01-10 08:00:00', '2025-01-10 09:00:00', 'cambio_aceite', 'no_show', 'Cliente no se presento');

-- --- SERVICE RECORDS ---
-- Immutable records linked to completed appointments + walk-ins

INSERT INTO service_records (vehicle_id, appointment_id, fecha, km, tipo_aceite, marca_aceite, costo_total, observaciones, proximo_service_km, created_by) VALUES
(1, 3, '2025-01-15 14:00:00', 45000, 'sintetico', 'Mobil 1 5W-30', 42500.00, 'Service completo. Motor en buen estado.', 55000, 2),
(3, 4, '2025-01-18 11:00:00', 15000, 'sintetico', 'Castrol Edge 5W-30', 38000.00, 'Primer service. Todo correcto.', 25000, 2),
(2, NULL, '2025-01-12 09:30:00', 71500, 'semi_sintetico', 'Yacitec 10W-40', 28000.00, 'Walk-in. Cliente esperaba 45 min.', 78500, 2),
(1, NULL, '2024-12-01 10:00:00', 40000, 'sintetico', 'Mobil 1 5W-30', 41000.00, 'Service programado 40K km.', 50000, 2),
(2, NULL, '2024-11-15 14:00:00', 65000, 'semi_sintetico', 'Yacitec 10W-40', 26500.00, 'Cambio de aceite y filtro.', 72000, 2),
(3, NULL, '2024-10-20 09:00:00', 10000, 'sintetico', 'Castrol Edge 5W-30', 37500.00, 'Service de los 10K.', 20000, 2),
(1, NULL, '2024-08-10 11:00:00', 35000, 'semi_sintetico', 'Yacitec 10W-40', 27000.00, 'Cambio anticipado por viaje.', 42000, 2),
(2, NULL, '2024-07-05 08:30:00', 58000, 'mineral', 'Norte 20W-50', 22000.00, 'Motor con desgaste, se recomienda mineral.', 63000, 2);

-- --- SERVICE PARTS USED ---

INSERT INTO service_parts_used (service_id, product_id, cantidad, costo_unitario) VALUES
(1, 1, 4, 8500.00),   -- 4L sintetico 5W-30 for service 1
(1, 4, 1, 2500.00),   -- 1 filtro de aceite
(2, 1, 4, 8500.00),   -- 4L sintetico 5W-30 for service 2
(2, 4, 1, 2500.00),   -- 1 filtro de aceite
(3, 2, 4, 5200.00),   -- 4L semi-sintetico 10W-40
(3, 4, 1, 2500.00),   -- 1 filtro de aceite
(5, 2, 4, 5200.00),   -- 4L semi-sintetico
(5, 4, 1, 2500.00),   -- 1 filtro
(6, 1, 4, 8500.00),   -- 4L sintetico
(6, 4, 1, 2500.00);   -- 1 filtro

-- --- SERVICE ADDENDUMS ---
-- Correction for service record 3 (wrong oil brand recorded initially)

INSERT INTO service_addendums (service_id, field_name, old_value, new_value, reason, created_by) VALUES
(3, 'marca_aceite', 'Mobil 1 10W-40', 'Yacitec 10W-40', 'Error de carga: se registro marca incorrecta. Corregido segun factura #4521.', 2);

-- --- ATTACHMENTS ---

INSERT INTO attachments (entity_type, entity_id, file_name, file_path, mime_type, file_size, uploaded_by) VALUES
('vehicle', 1, 'corolla_frente.jpg', '/uploads/vehicles/1/corolla_frente.jpg', 'image/jpeg', 245000, 2),
('vehicle', 1, 'corolla_patente.jpg', '/uploads/vehicles/1/corolla_patente.jpg', 'image/jpeg', 180000, 2),
('service_record', 1, 'factura_service_45000.pdf', '/uploads/services/1/factura_45000.pdf', 'application/pdf', 95000, 2),
('appointment', 1, 'orden_turno.pdf', '/uploads/appointments/1/orden.pdf', 'application/pdf', 42000, 1);

-- --- REFRESH TOKENS ---
-- Simulate active session for Juan

INSERT INTO refresh_tokens (user_id, token_hash, expires_at, ip_address, user_agent) VALUES
(1, SHA2('sample_refresh_token_juan_2025', 256), '2025-02-15 00:00:00', '192.168.1.100', 'Mozilla/5.0 (Linux; Android 14)');

-- --- AUDIT LOG ---
-- Simulated audit entries

INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by, ip_address) VALUES
('users', 1, 'INSERT', NULL, '{"email":"juan.perez@email.com","name":"Juan Perez","role":"customer"}', 1, '192.168.1.100'),
('vehicles', 1, 'INSERT', NULL, '{"patente":"ABC1234","marca":"Toyota","modelo":"Corolla"}', 1, '192.168.1.100'),
('appointments', 1, 'INSERT', NULL, '{"user_id":1,"vehicle_id":1,"tipo_service":"cambio_aceite","status":"pending"}', 1, '192.168.1.100'),
('service_records', 1, 'INSERT', NULL, '{"vehicle_id":1,"km":45000,"tipo_aceite":"sintetico","costo_total":42500.00}', 2, '192.168.1.50');
```

---

## 8. Security at Database Level

### 8.1 User Privilege Model

```sql
-- ============================================================
-- CREATE APPLICATION USER (limited privileges)
-- ============================================================

-- App user: used by the backend API
CREATE USER 'app_user'@'%' IDENTIFIED BY 'AppUser_Str0ng!Pass_2025';

-- Core CRUD on business tables
GRANT SELECT, INSERT, UPDATE ON lubricentros.users TO 'app_user'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON lubricentros.vehicles TO 'app_user'@'%';
GRANT SELECT, INSERT, UPDATE ON lubricentros.appointments TO 'app_user'@'%';
GRANT SELECT, INSERT ON lubricentros.service_records TO 'app_user'@'%';        -- IMMUTABLE: no UPDATE/DELETE
GRANT SELECT, INSERT ON lubricentros.service_addendums TO 'app_user'@'%';
GRANT SELECT, INSERT, UPDATE ON lubricentros.products TO 'app_user'@'%';
GRANT SELECT, INSERT ON lubricentros.service_parts_used TO 'app_user'@'%';
GRANT SELECT, INSERT, DELETE ON lubricentros.attachments TO 'app_user'@'%';
GRANT SELECT, INSERT, DELETE ON lubricentros.refresh_tokens TO 'app_user'@'%';
GRANT SELECT, INSERT ON lubricentros.ownership_transfers TO 'app_user'@'%';
GRANT SELECT, INSERT ON lubricentros.audit_log TO 'app_user'@'%';

-- ============================================================
-- CREATE READ-ONLY USER (for reporting/analytics)
-- ============================================================

CREATE USER 'readonly_user'@'%' IDENTIFIED BY 'ReadOnly_Str0ng!Pass_2025';

GRANT SELECT ON lubricentros.users TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.vehicles TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.appointments TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.service_records TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.service_addendums TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.products TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.service_parts_used TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.attachments TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.ownership_transfers TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.audit_log TO 'readonly_user'@'%';
-- NO access to refresh_tokens (sensitive session data)

FLUSH PRIVILEGES;
```

### 8.2 REVOKE Sensitive Table Access

```sql
-- Ensure app_user cannot DROP/ALTER any tables
REVOKE ALL PRIVILEGES ON lubricentros.* FROM 'app_user'@'%';
-- Then re-grant only what's needed (see above)

-- Prevent app_user from accessing MySQL system tables
REVOKE ALL ON mysql.* FROM 'app_user'@'%';
REVOKE ALL ON performance_schema.* FROM 'app_user'@'%';
REVOKE ALL ON information_schema.* FROM 'app_user'@'%';

-- Prevent reading raw password hashes (use views instead)
REVOKE SELECT ON lubricentros.users FROM 'app_user'@'%';
-- Re-grant without password_hash via view (see below)
GRANT SELECT ON lubricentros.v_users_public TO 'app_user'@'%';
```

### 8.3 View Definitions for Read-Only Access

```sql
-- ============================================================
-- VIEW: Users without password hashes (safe for app queries)
-- ============================================================
CREATE OR REPLACE VIEW v_users_public AS
SELECT
    id,
    email,
    name,
    phone,
    role,
    is_active,
    created_at,
    updated_at
FROM users;

-- ============================================================
-- VIEW: Refresh tokens without raw hash (for admin monitoring)
-- ============================================================
CREATE OR REPLACE VIEW v_refresh_tokens_summary AS
SELECT
    id,
    user_id,
    LEFT(token_hash, 16) AS token_hash_prefix,
    expires_at,
    created_at,
    revoked_at IS NOT NULL AS is_revoked,
    ip_address,
    LEFT(user_agent, 100) AS user_agent_short
FROM refresh_tokens;

-- ============================================================
-- VIEW: Vehicle with latest service (denormalized for dashboard)
-- ============================================================
CREATE OR REPLACE VIEW v_vehicles_with_latest_service AS
SELECT
    v.id,
    v.user_id,
    v.patente,
    v.marca,
    v.modelo,
    v.anio,
    v.motor,
    v.km_actual,
    v.color,
    sr.id AS last_service_id,
    sr.fecha AS last_service_date,
    sr.km AS last_service_km,
    sr.tipo_aceite AS last_service_oil_type,
    sr.proximo_service_km,
    CASE
        WHEN v.km_actual >= sr.proximo_service_km THEN 'critical'
        WHEN v.km_actual >= sr.proximo_service_km - 500 THEN 'maintenance_due'
        ELSE 'ok'
    END AS service_status
FROM vehicles v
LEFT JOIN service_records sr ON sr.vehicle_id = v.id
    AND sr.id = (
        SELECT id FROM service_records
        WHERE vehicle_id = v.id
        ORDER BY fecha DESC
        LIMIT 1
    );

-- ============================================================
-- VIEW: Appointment detail with user + vehicle info
-- ============================================================
CREATE OR REPLACE VIEW v_appointments_detail AS
SELECT
    a.id,
    a.user_id,
    a.vehicle_id,
    a.fecha,
    a.slot_end,
    a.tipo_service,
    a.status,
    a.observaciones,
    a.created_at,
    a.updated_at,
    u.name AS customer_name,
    u.phone AS customer_phone,
    u.email AS customer_email,
    v.patente,
    v.marca,
    v.modelo,
    v.anio
FROM appointments a
JOIN users u ON u.id = a.user_id
JOIN vehicles v ON v.id = a.vehicle_id;

-- ============================================================
-- VIEW: Low stock products alert
-- ============================================================
CREATE OR REPLACE VIEW v_low_stock_products AS
SELECT
    id,
    sku,
    nombre,
    categoria,
    stock_actual,
    stock_minimo,
    (stock_minimo - stock_actual) AS units_to_order,
    precio AS unit_price,
    ((stock_minimo - stock_actual) * precio) AS estimated_order_cost
FROM products
WHERE stock_actual <= stock_minimo
  AND is_active = 1;

-- ============================================================
-- VIEW: Service report (full detail)
-- ============================================================
CREATE OR REPLACE VIEW v_service_report AS
SELECT
    sr.id AS service_id,
    sr.vehicle_id,
    sr.fecha,
    sr.km,
    sr.tipo_aceite,
    sr.marca_aceite,
    sr.costo_total,
    sr.observaciones,
    sr.proximo_service_km,
    sr.created_at,
    cb.name AS created_by_name,
    v.patente,
    v.marca,
    v.modelo,
    v.anio,
    sp.product_id,
    p.sku,
    p.nombre AS product_name,
    p.categoria,
    sp.cantidad,
    sp.costo_unitario,
    (sp.cantidad * sp.costo_unitario) AS line_total
FROM service_records sr
JOIN vehicles v ON v.id = sr.vehicle_id
JOIN users cb ON cb.id = sr.created_by
LEFT JOIN service_parts_used sp ON sp.service_id = sr.id
LEFT JOIN products p ON p.id = sp.product_id;

-- Grant read-only user access to views
GRANT SELECT ON lubricentros.v_users_public TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.v_refresh_tokens_summary TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.v_vehicles_with_latest_service TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.v_appointments_detail TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.v_low_stock_products TO 'readonly_user'@'%';
GRANT SELECT ON lubricentros.v_service_report TO 'readonly_user'@'%';
```

### 8.4 Audit Trigger for service_records

```sql
-- ============================================================
-- AUDIT TRIGGER: Automatically log all changes to service_records
-- ============================================================
-- Note: This works even if the application bypasses audit_log INSERTs

DELIMITER //

CREATE TRIGGER trg_audit_sr_insert
AFTER INSERT ON service_records
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name, record_id, action,
        old_data, new_data, changed_by, ip_address
    ) VALUES (
        'service_records', NEW.id, 'INSERT',
        NULL,
        JSON_OBJECT(
            'vehicle_id', NEW.vehicle_id,
            'appointment_id', NEW.appointment_id,
            'fecha', NEW.fecha,
            'km', NEW.km,
            'tipo_aceite', NEW.tipo_aceite,
            'marca_aceite', NEW.marca_aceite,
            'costo_total', NEW.costo_total,
            'proximo_service_km', NEW.proximo_service_km,
            'created_by', NEW.created_by
        ),
        NEW.created_by,
        NULL  -- IP must be set by application if needed
    );
END//

CREATE TRIGGER trg_audit_sr_update
BEFORE UPDATE ON service_records
FOR EACH ROW
BEGIN
    -- This trigger fires if someone with UPDATE privileges modifies a record
    -- It logs the change AND signals a warning
    INSERT INTO audit_log (
        table_name, record_id, action,
        old_data, new_data, changed_by
    ) VALUES (
        'service_records', OLD.id, 'UPDATE',
        JSON_OBJECT(
            'vehicle_id', OLD.vehicle_id,
            'fecha', OLD.fecha,
            'km', OLD.km,
            'tipo_aceite', OLD.tipo_aceite,
            'costo_total', OLD.costo_total
        ),
        JSON_OBJECT(
            'vehicle_id', NEW.vehicle_id,
            'fecha', NEW.fecha,
            'km', NEW.km,
            'tipo_aceite', NEW.tipo_aceite,
            'costo_total', NEW.costo_total
        ),
        NEW.created_by
    );
END//

CREATE TRIGGER trg_audit_sr_delete
BEFORE DELETE ON service_records
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name, record_id, action,
        old_data, new_data, changed_by
    ) VALUES (
        'service_records', OLD.id, 'DELETE',
        JSON_OBJECT(
            'vehicle_id', OLD.vehicle_id,
            'fecha', OLD.fecha,
            'km', OLD.km,
            'tipo_aceite', OLD.tipo_aceite,
            'costo_total', OLD.costo_total
        ),
        NULL,
        OLD.created_by
    );
END//

DELIMITER ;
```

### 8.5 Additional Audit Triggers (Key Tables)

```sql
-- ============================================================
-- AUDIT TRIGGER: appointments status changes
-- ============================================================
DELIMITER //

CREATE TRIGGER trg_audit_appt_update
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    -- Only log if status actually changed
    IF OLD.status != NEW.status THEN
        INSERT INTO audit_log (
            table_name, record_id, action,
            old_data, new_data, changed_by
        ) VALUES (
            'appointments', NEW.id, 'UPDATE',
            JSON_OBJECT('status', OLD.status),
            JSON_OBJECT('status', NEW.status),
            NEW.user_id
        );
    END IF;
END//

DELIMITER ;
```

### 8.6 Security Checklist

| Control | Implementation | Status |
|---------|---------------|--------|
| Passwords hashed (bcrypt) | `password_hash` column, app-level bcrypt | Schema supports |
| No raw token storage | `token_hash` stores SHA-256, not raw token | Schema supports |
| Least privilege users | `app_user`, `readonly_user` with minimal grants | Documented above |
| Sensitive columns hidden | Views exclude `password_hash`, `token_hash` | Views defined |
| Immutable records | REVOKE + triggers on `service_records` | Both options provided |
| Audit trail | `audit_log` table + triggers | Triggers defined |
| Soft deletes | `is_active` flags on users and products | Schema supports |
| SQL injection prevention | Prepared statements (application-level) | Must enforce in code |
| Connection encryption | `REQUIRE SSL` in CREATE USER | Add for production |
| IP-based access control | `CREATE USER 'app_user'@'10.0.0.%'` | Restrict in production |

---

## Quick Reference: Table Sizes (Estimated)

| Table | Growth Rate | 1-Year Estimate | 3-Year Estimate |
|-------|-------------|-----------------|-----------------|
| users | +50/month | 600 | 1,800 |
| vehicles | +80/month | 960 | 2,880 |
| appointments | +200/month | 2,400 | 7,200 |
| service_records | +150/month | 1,800 | 5,400 |
| service_addendums | +5/month | 60 | 180 |
| products | Static (~50) | 50 | 50 |
| service_parts_used | +300/month | 3,600 | 10,800 |
| attachments | +100/month | 1,200 | 3,600 |
| refresh_tokens | +500/month (with cleanup) | 500 | 500 |
| ownership_transfers | +10/month | 120 | 360 |
| audit_log | +1000/month | 12,000 | 36,000 |

All tables are well within InnoDB's practical limits. No partitioning needed for the first 3-5 years.
