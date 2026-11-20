-- +goose Up
-- ============================================================
-- LUBRICENTROS SaaS — Initial Schema (PostgreSQL / Supabase)
-- ============================================================

-- ENUM types
-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM('customer', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE ownership_transfer_status AS ENUM('requested', 'completed', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE appointment_status AS ENUM('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE service_type AS ENUM('cambio_aceite', 'alineacion', 'mecanica_luces', 'revision_general', 'otro');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE oil_type AS ENUM('mineral', 'semi_sintetico', 'sintetico');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE product_category AS ENUM('aceite', 'filtro', 'frenos', 'neumaticos', 'bateria', 'aditivo', 'otro');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE attachment_entity_type AS ENUM('vehicle', 'service_record', 'appointment');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$ BEGIN
    CREATE TYPE audit_action AS ENUM('INSERT', 'UPDATE', 'DELETE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- +goose StatementEnd

-- 1) USERS
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    name            VARCHAR(255) NOT NULL,
    phone           VARCHAR(20) DEFAULT NULL,
    role            user_role NOT NULL DEFAULT 'customer',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- 2) VEHICLES
CREATE TABLE IF NOT EXISTS vehicles (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL,
    patente         VARCHAR(10) DEFAULT NULL,
    marca           VARCHAR(100) NOT NULL,
    modelo          VARCHAR(100) NOT NULL,
    anio            SMALLINT NOT NULL,
    motor           VARCHAR(100) DEFAULT NULL,
    km_actual       INT NOT NULL DEFAULT 0,
    color           VARCHAR(50) DEFAULT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_vehicles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_vehicles_user ON vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_patente ON vehicles(patente);
CREATE INDEX IF NOT EXISTS idx_vehicles_marca_modelo ON vehicles(marca, modelo);

-- 3) OWNERSHIP_TRANSFERS
CREATE TABLE IF NOT EXISTS ownership_transfers (
    id              SERIAL PRIMARY KEY,
    vehicle_id      INT NOT NULL,
    from_user_id    INT DEFAULT NULL,
    to_user_id      INT NOT NULL,
    transferred_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason          VARCHAR(255) DEFAULT NULL,
    initiated_by    INT DEFAULT NULL,
    status          ownership_transfer_status NOT NULL DEFAULT 'completed',
    notes           TEXT DEFAULT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ot_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_ot_from_user FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_ot_to_user FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ot_initiated_by FOREIGN KEY (initiated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_ot_vehicle ON ownership_transfers(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_ot_from_user ON ownership_transfers(from_user_id);
CREATE INDEX IF NOT EXISTS idx_ot_to_user ON ownership_transfers(to_user_id);

-- 4) APPOINTMENTS
CREATE TABLE IF NOT EXISTS appointments (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL,
    vehicle_id      INT NOT NULL,
    fecha           TIMESTAMP NOT NULL,
    slot_end        TIMESTAMP NOT NULL,
    tipo_service    service_type NOT NULL,
    status          appointment_status NOT NULL DEFAULT 'pending',
    observaciones   TEXT DEFAULT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appt_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_appt_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_appt_user ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appt_vehicle ON appointments(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_appt_fecha ON appointments(fecha);
CREATE INDEX IF NOT EXISTS idx_appt_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appt_user_status ON appointments(user_id, status);

-- 5) SERVICE_RECORDS
CREATE TABLE IF NOT EXISTS service_records (
    id                  SERIAL PRIMARY KEY,
    vehicle_id          INT NOT NULL,
    appointment_id      INT DEFAULT NULL,
    fecha               TIMESTAMP NOT NULL,
    km                  INT NOT NULL,
    tipo_aceite         oil_type NOT NULL,
    marca_aceite        VARCHAR(100) DEFAULT NULL,
    costo_total         NUMERIC(10,2) DEFAULT NULL,
    observaciones       TEXT DEFAULT NULL,
    proximo_service_km  INT DEFAULT NULL,
    created_by          INT NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sr_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_sr_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL,
    CONSTRAINT fk_sr_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_sr_vehicle ON service_records(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_sr_fecha ON service_records(fecha DESC);
CREATE INDEX IF NOT EXISTS idx_sr_vehicle_fecha ON service_records(vehicle_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_sr_km ON service_records(km);

-- 6) SERVICE_ADDENDUMS
CREATE TABLE IF NOT EXISTS service_addendums (
    id              SERIAL PRIMARY KEY,
    service_id      INT NOT NULL,
    field_name      VARCHAR(100) NOT NULL,
    old_value       TEXT DEFAULT NULL,
    new_value       TEXT NOT NULL,
    reason          TEXT NOT NULL,
    created_by      INT NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sa_service FOREIGN KEY (service_id) REFERENCES service_records(id) ON DELETE CASCADE,
    CONSTRAINT fk_sa_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_sa_service ON service_addendums(service_id);

-- 7) PRODUCTS
CREATE TABLE IF NOT EXISTS products (
    id              SERIAL PRIMARY KEY,
    sku             VARCHAR(50) NOT NULL,
    nombre          VARCHAR(255) NOT NULL,
    categoria       product_category NOT NULL,
    descripcion     TEXT DEFAULT NULL,
    precio          NUMERIC(10,2) NOT NULL,
    stock_actual    INT NOT NULL DEFAULT 0,
    stock_minimo    INT NOT NULL DEFAULT 5,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_categoria ON products(categoria, is_active);

-- 8) SERVICE_PARTS_USED
CREATE TABLE IF NOT EXISTS service_parts_used (
    id              SERIAL PRIMARY KEY,
    service_id      INT NOT NULL,
    product_id      INT NOT NULL,
    cantidad        INT NOT NULL,
    costo_unitario  NUMERIC(10,2) NOT NULL,
    CONSTRAINT fk_spu_service FOREIGN KEY (service_id) REFERENCES service_records(id) ON DELETE CASCADE,
    CONSTRAINT fk_spu_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_spu_service ON service_parts_used(service_id);
CREATE INDEX IF NOT EXISTS idx_spu_product ON service_parts_used(product_id);

-- 9) ATTACHMENTS
CREATE TABLE IF NOT EXISTS attachments (
    id              SERIAL PRIMARY KEY,
    entity_type     attachment_entity_type NOT NULL,
    entity_id       INT NOT NULL,
    file_name       VARCHAR(255) NOT NULL,
    file_path       VARCHAR(500) NOT NULL,
    mime_type       VARCHAR(100) NOT NULL,
    file_size       INT NOT NULL,
    uploaded_by     INT NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_att_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_att_entity ON attachments(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_att_uploaded_by ON attachments(uploaded_by);

-- 10) REFRESH_TOKENS
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL,
    token_hash      VARCHAR(255) NOT NULL,
    expires_at      TIMESTAMP NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at      TIMESTAMP DEFAULT NULL,
    ip_address      VARCHAR(45) DEFAULT NULL,
    user_agent      TEXT DEFAULT NULL,
    CONSTRAINT fk_rt_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_rt_token_hash ON refresh_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_rt_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_rt_expires ON refresh_tokens(expires_at);

-- 11) AUDIT_LOG
CREATE TABLE IF NOT EXISTS audit_log (
    id              SERIAL PRIMARY KEY,
    table_name      VARCHAR(100) NOT NULL,
    record_id       INT NOT NULL,
    action          audit_action NOT NULL,
    old_data        JSONB DEFAULT NULL,
    new_data        JSONB DEFAULT NULL,
    changed_by      INT DEFAULT NULL,
    changed_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address      VARCHAR(45) DEFAULT NULL,
    CONSTRAINT fk_audit_changed_by FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_table_record ON audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_changed_at ON audit_log(changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_changed_by ON audit_log(changed_by);

-- updated_at trigger function
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
        CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_vehicles_updated_at') THEN
        CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_appointments_updated_at') THEN
        CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_products_updated_at') THEN
        CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
-- +goose StatementEnd

-- +goose Down
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
DROP TRIGGER IF EXISTS update_appointments_updated_at ON appointments;
DROP TRIGGER IF EXISTS update_vehicles_updated_at ON vehicles;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP FUNCTION IF EXISTS update_updated_at_column();

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

DROP TYPE IF EXISTS audit_action;
DROP TYPE IF EXISTS attachment_entity_type;
DROP TYPE IF EXISTS product_category;
DROP TYPE IF EXISTS oil_type;
DROP TYPE IF EXISTS service_type;
DROP TYPE IF EXISTS appointment_status;
DROP TYPE IF EXISTS ownership_transfer_status;
DROP TYPE IF EXISTS user_role;
