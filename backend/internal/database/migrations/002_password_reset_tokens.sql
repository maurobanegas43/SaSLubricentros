-- +goose Up
-- ============================================================
-- Password Reset Tokens Table
-- ============================================================

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED    NOT NULL,
    token           VARCHAR(255)    NOT NULL COMMENT 'Cryptographically secure random token',
    expires_at      DATETIME        NOT NULL COMMENT 'Token expiration (1 hour from creation)',
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_prt_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    INDEX idx_prt_token (token),
    INDEX idx_prt_expires_at (expires_at),
    INDEX idx_prt_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- +goose Down
DROP TABLE IF EXISTS password_reset_tokens;
