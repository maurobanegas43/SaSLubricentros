-- ============================================================
-- LUBRICENTROS SaaS — Migración Inicial PostgreSQL/Supabase
-- ============================================================
-- Schema para seguridad de contraseñas (password_hash)
-- ============================================================

-- ENUM Types
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM('customer', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- USERS - con password_hash seguro (NO password VARCHAR)
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255)    NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    name            VARCHAR(255)    NOT NULL,
    phone           VARCHAR(20)     DEFAULT NULL,
    role            user_role      NOT NULL DEFAULT 'customer',
    is_active       BOOLEAN        NOT NULL DEFAULT true,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- SECURITY: password_hash es el único campo de contraseña
-- Nunca usar password VARCHAR sin _hash o _reset