-- +goose Up
-- ============================================================
-- LUBRICENTROS SaaS — Initial Schema (MariaDB)
-- ============================================================
-- Motor: MariaDB 10.6+
-- Charset: utf8mb4 / Collation: utf8mb4_unicode_ci
-- ============================================================

-- 1. USERS — Usuarios del sistema
CREATE TABLE IF NOT EXISTS users (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email           VARCHAR(255)    NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL COMMENT 'bcrypt hash',
    name            VARCHAR(255)    NOT NULL,
    phone           VARCHAR(20)     DEFAULT NULL,
    role            ENUM('customer', 'admin') NOT NULL DEFAULT 'customer',
    is_active       TINYINT(1)      NOT NULL DEFAULT 1 COMMENT '1=activo, 0=desactivado',
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. VEHICLES — Vehículos registrados
CREATE TABLE IF NOT EXISTS vehicles (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED    NOT NULL COMMENT 'Propietario actual',
    patente         VARCHAR(10)     DEFAULT NULL COMMENT 'Patente argentina (ABC123 / AB123CD)',
    marca           VARCHAR(100)    NOT NULL,
    modelo          VARCHAR(100)    NOT NULL,
    anio            SMALLINT        NOT NULL,
    motor           VARCHAR(100)    DEFAULT NULL,
    km_actual       INT UNSIGNED    NOT NULL DEFAULT 0,
    color           VARCHAR(50)     DEFAULT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_vehicles_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    INDEX idx_vehicles_user (user_id),
    INDEX idx_vehicles_patente (patente),
    INDEX idx_vehicles_marca_modelo (marca, modelo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. OWNERSHIP_TRANSFERS — Historial de cambios de dueño
CREATE TABLE IF NOT EXISTS ownership_transfers (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id      INT UNSIGNED    NOT NULL,
    from_user_id    INT UNSIGNED    DEFAULT NULL COMMENT 'Dueño anterior',
    to_user_id      INT UNSIGNED    NOT NULL COMMENT 'Nuevo dueño',
    transferred_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason          VARCHAR(255)    DEFAULT NULL,
    initiated_by    INT UNSIGNED    DEFAULT NULL COMMENT 'Quién inició (puede ser admin)',
    status          ENUM('requested', 'completed', 'rejected') NOT NULL DEFAULT 'completed',
    notes           TEXT            DEFAULT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ot_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_ot_from_user
        FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_ot_to_user
        FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ot_initiated_by
        FOREIGN KEY (initiated_by) REFERENCES users(id) ON DELETE SET NULL,

    INDEX idx_ot_vehicle (vehicle_id),
    INDEX idx_ot_from_user (from_user_id),
    INDEX idx_ot_to_user (to_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. APPOINTMENTS — Turnos agendados
CREATE TABLE IF NOT EXISTS appointments (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED    NOT NULL COMMENT 'Cliente que reserva',
    vehicle_id      INT UNSIGNED    NOT NULL,
    fecha           DATETIME        NOT NULL COMMENT 'Fecha y hora del turno',
    slot_end        DATETIME        NOT NULL COMMENT 'Hora estimada de fin',
    tipo_service    ENUM('cambio_aceite', 'alineacion', 'mecanica_luces', 'revision_general', 'otro') NOT NULL,
    status          ENUM('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show') NOT NULL DEFAULT 'pending',
    observaciones   TEXT            DEFAULT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_appt_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_appt_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,

    INDEX idx_appt_user (user_id),
    INDEX idx_appt_vehicle (vehicle_id),
    INDEX idx_appt_fecha (fecha),
    INDEX idx_appt_status (status),
    INDEX idx_appt_user_status (user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. SERVICE_RECORDS — Historial de servicios (INMUTABLE)
CREATE TABLE IF NOT EXISTS service_records (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id          INT UNSIGNED    NOT NULL,
    appointment_id      INT UNSIGNED    DEFAULT NULL COMMENT 'Turno asociado (si aplica)',
    fecha               DATETIME        NOT NULL,
    km                  INT UNSIGNED    NOT NULL,
    tipo_aceite         ENUM('mineral', 'semi_sintetico', 'sintetico') NOT NULL,
    marca_aceite        VARCHAR(100)    DEFAULT NULL,
    costo_total         DECIMAL(10,2)   DEFAULT NULL,
    observaciones       TEXT            DEFAULT NULL,
    proximo_service_km  INT UNSIGNED    DEFAULT NULL,
    created_by          INT UNSIGNED    NOT NULL COMMENT 'Mecánico/admin que registró',
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sr_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_sr_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL,
    CONSTRAINT fk_sr_created_by
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,

    INDEX idx_sr_vehicle (vehicle_id),
    INDEX idx_sr_fecha (fecha DESC),
    INDEX idx_sr_vehicle_fecha (vehicle_id, fecha DESC),
    INDEX idx_sr_km (km)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. SERVICE_ADDENDUMS — Correcciones a registros inmutables
CREATE TABLE IF NOT EXISTS service_addendums (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id      INT UNSIGNED    NOT NULL,
    field_name      VARCHAR(100)    NOT NULL COMMENT 'Campo corregido',
    old_value       TEXT            DEFAULT NULL,
    new_value       TEXT            NOT NULL,
    reason          TEXT            NOT NULL COMMENT 'Motivo de la corrección',
    created_by      INT UNSIGNED    NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sa_service
        FOREIGN KEY (service_id) REFERENCES service_records(id) ON DELETE CASCADE,
    CONSTRAINT fk_sa_created_by
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,

    INDEX idx_sa_service (service_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. PRODUCTS — Inventario de productos/insumos
CREATE TABLE IF NOT EXISTS products (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku             VARCHAR(50)     NOT NULL,
    nombre          VARCHAR(255)    NOT NULL,
    categoria       ENUM('aceite', 'filtro', 'frenos', 'neumaticos', 'bateria', 'aditivo', 'otro') NOT NULL,
    descripcion     TEXT            DEFAULT NULL,
    precio          DECIMAL(10,2)   NOT NULL,
    stock_actual    INT             NOT NULL DEFAULT 0,
    stock_minimo    INT             NOT NULL DEFAULT 5,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_products_sku (sku),
    INDEX idx_products_categoria (categoria, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. SERVICE_PARTS_USED — Productos usados en cada servicio
CREATE TABLE IF NOT EXISTS service_parts_used (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_id      INT UNSIGNED    NOT NULL,
    product_id      INT UNSIGNED    NOT NULL,
    cantidad        INT UNSIGNED    NOT NULL,
    costo_unitario  DECIMAL(10,2)   NOT NULL,

    CONSTRAINT fk_spu_service
        FOREIGN KEY (service_id) REFERENCES service_records(id) ON DELETE CASCADE,
    CONSTRAINT fk_spu_product
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,

    INDEX idx_spu_service (service_id),
    INDEX idx_spu_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. ATTACHMENTS — Imágenes y archivos adjuntos
CREATE TABLE IF NOT EXISTS attachments (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entity_type     ENUM('vehicle', 'service_record', 'appointment') NOT NULL,
    entity_id       INT UNSIGNED    NOT NULL,
    file_name       VARCHAR(255)    NOT NULL,
    file_path       VARCHAR(500)    NOT NULL,
    mime_type       VARCHAR(100)    NOT NULL,
    file_size       INT UNSIGNED    NOT NULL,
    uploaded_by     INT UNSIGNED    NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_att_uploaded_by
        FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE,

    INDEX idx_att_entity (entity_type, entity_id),
    INDEX idx_att_uploaded_by (uploaded_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. REFRESH_TOKENS — Tokens de refresco JWT
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED    NOT NULL,
    token_hash      VARCHAR(255)    NOT NULL COMMENT 'SHA-256 del token real',
    expires_at      DATETIME        NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at      TIMESTAMP       DEFAULT NULL,
    ip_address      VARCHAR(45)     DEFAULT NULL COMMENT 'IPv4 o IPv6',
    user_agent      TEXT            DEFAULT NULL,

    CONSTRAINT fk_rt_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    UNIQUE KEY uq_rt_token_hash (token_hash),
    INDEX idx_rt_user (user_id),
    INDEX idx_rt_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. AUDIT_LOG — Log de auditoría general
CREATE TABLE IF NOT EXISTS audit_log (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name      VARCHAR(100)    NOT NULL,
    record_id       INT UNSIGNED    NOT NULL,
    action          ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_data        JSON            DEFAULT NULL,
    new_data        JSON            DEFAULT NULL,
    changed_by      INT UNSIGNED    DEFAULT NULL,
    changed_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address      VARCHAR(45)     DEFAULT NULL,

    CONSTRAINT fk_audit_changed_by
        FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL,

    INDEX idx_audit_table_record (table_name, record_id),
    INDEX idx_audit_changed_at (changed_at DESC),
    INDEX idx_audit_changed_by (changed_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- +goose Down
-- Reverse order: drop tables that depend on others first
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS attachments;
DROP TABLE IF EXISTS service_parts_used;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS service_addendums;
DROP TABLE IF EXISTS service_records;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS ownership_transfers;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS users;
