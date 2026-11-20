package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// RefreshTokenRepositoryImpl is the MariaDB implementation of RefreshTokenRepository.
type RefreshTokenRepositoryImpl struct {
	*BaseRepository
}

// NewRefreshTokenRepository creates a new refresh token repository.
func NewRefreshTokenRepository(db *sql.DB) *RefreshTokenRepositoryImpl {
	return &RefreshTokenRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create stores a new refresh token.
func (r *RefreshTokenRepositoryImpl) Create(ctx context.Context, token *entity.RefreshToken) error {
	query := `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, created_at, ip_address, user_agent)
		VALUES (?, ?, ?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	token.CreatedAt = now

	var id int64
	err := r.QueryRowContext(ctx, query,
		token.UserID, token.TokenHash, token.ExpiresAt,
		token.CreatedAt, token.IPAddress, token.UserAgent,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "refresh token create")
	}

	token.ID = uint(id)

	return nil
}

// GetByTokenHash retrieves a refresh token by its hash.
func (r *RefreshTokenRepositoryImpl) GetByTokenHash(ctx context.Context, tokenHash string) (*entity.RefreshToken, error) {
	query := `SELECT id, user_id, token_hash, expires_at, created_at, revoked_at, ip_address, user_agent
		FROM refresh_tokens WHERE token_hash = ?`

	var t entity.RefreshToken
	err := r.QueryRowContext(ctx, query, tokenHash).Scan(
		&t.ID, &t.UserID, &t.TokenHash, &t.ExpiresAt,
		&t.CreatedAt, &t.RevokedAt, &t.IPAddress, &t.UserAgent,
	)
	if err != nil {
		return nil, WrapError(err, "refresh token get by token hash")
	}

	return &t, nil
}

// GetByUserID retrieves all refresh tokens for a user.
func (r *RefreshTokenRepositoryImpl) GetByUserID(ctx context.Context, userID uint) ([]entity.RefreshToken, error) {
	query := `SELECT id, user_id, token_hash, expires_at, created_at, revoked_at, ip_address, user_agent
		FROM refresh_tokens WHERE user_id = ? ORDER BY created_at DESC`

	rows, err := r.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, WrapError(err, "refresh token get by user id")
	}
	defer rows.Close()

	var tokens []entity.RefreshToken
	for rows.Next() {
		var t entity.RefreshToken
		if err := rows.Scan(
			&t.ID, &t.UserID, &t.TokenHash, &t.ExpiresAt,
			&t.CreatedAt, &t.RevokedAt, &t.IPAddress, &t.UserAgent,
		); err != nil {
			return nil, WrapError(err, "refresh token get by user id: scan")
		}
		tokens = append(tokens, t)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "refresh token get by user id: iterate")
	}

	return tokens, nil
}

// Revoke marks a refresh token as revoked.
func (r *RefreshTokenRepositoryImpl) Revoke(ctx context.Context, tokenHash string) error {
	query := `UPDATE refresh_tokens SET revoked_at = ? WHERE token_hash = ?`

	now := time.Now()
	result, err := r.ExecContext(ctx, query, now, tokenHash)
	if err != nil {
		return WrapError(err, "refresh token revoke")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "refresh token revoke: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "refresh token revoke")
	}

	return nil
}

// RevokeAllByUserID revokes all refresh tokens for a user.
func (r *RefreshTokenRepositoryImpl) RevokeAllByUserID(ctx context.Context, userID uint) error {
	query := `UPDATE refresh_tokens SET revoked_at = ? WHERE user_id = ? AND revoked_at IS NULL`

	now := time.Now()
	_, err := r.ExecContext(ctx, query, now, userID)
	if err != nil {
		return WrapError(err, "refresh token revoke all by user id")
	}

	return nil
}

// DeleteExpired removes expired refresh tokens from the database.
func (r *RefreshTokenRepositoryImpl) DeleteExpired(ctx context.Context) error {
	query := `DELETE FROM refresh_tokens WHERE expires_at < NOW()`

	_, err := r.ExecContext(ctx, query)
	if err != nil {
		return WrapError(err, "refresh token delete expired")
	}

	return nil
}
