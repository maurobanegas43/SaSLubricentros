package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// PasswordResetTokenRepositoryImpl is the MariaDB implementation of the PasswordResetTokenRepository interface
type PasswordResetTokenRepositoryImpl struct {
	*BaseRepository
}

// NewPasswordResetTokenRepository creates a new password reset token repository
func NewPasswordResetTokenRepository(db *sql.DB) *PasswordResetTokenRepositoryImpl {
	return &PasswordResetTokenRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new password reset token
func (r *PasswordResetTokenRepositoryImpl) Create(ctx context.Context, token *entity.PasswordResetToken) error {
	query := `INSERT INTO password_reset_tokens (user_id, token, expires_at, created_at)
		VALUES (?, ?, ?, ?)
		RETURNING id`

	token.CreatedAt = time.Now()

	var id int64
	err := r.QueryRowContext(ctx, query,
		token.UserID, token.Token, token.ExpiresAt, token.CreatedAt,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "password reset token create")
	}

	token.ID = uint(id)

	return nil
}

// GetByToken retrieves a password reset token by its token string
func (r *PasswordResetTokenRepositoryImpl) GetByToken(ctx context.Context, token string) (*entity.PasswordResetToken, error) {
	query := `SELECT id, user_id, token, expires_at, created_at
		FROM password_reset_tokens
		WHERE token = ?`

	var t entity.PasswordResetToken
	err := r.QueryRowContext(ctx, query, token).Scan(
		&t.ID, &t.UserID, &t.Token, &t.ExpiresAt, &t.CreatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "password reset token get by token")
	}

	return &t, nil
}

// Delete deletes a password reset token
func (r *PasswordResetTokenRepositoryImpl) Delete(ctx context.Context, token string) error {
	query := `DELETE FROM password_reset_tokens WHERE token = ?`

	result, err := r.ExecContext(ctx, query, token)
	if err != nil {
		return WrapError(err, "password reset token delete")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "password reset token delete: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "password reset token delete")
	}

	return nil
}

// DeleteByUserID deletes all password reset tokens for a user
func (r *PasswordResetTokenRepositoryImpl) DeleteByUserID(ctx context.Context, userID uint) error {
	query := `DELETE FROM password_reset_tokens WHERE user_id = ?`

	_, err := r.ExecContext(ctx, query, userID)
	if err != nil {
		return WrapError(err, "password reset token delete by user id")
	}

	return nil
}

// DeleteExpired deletes all expired password reset tokens
func (r *PasswordResetTokenRepositoryImpl) DeleteExpired(ctx context.Context) error {
	query := `DELETE FROM password_reset_tokens WHERE expires_at < NOW()`

	result, err := r.ExecContext(ctx, query)
	if err != nil {
		return WrapError(err, "password reset token delete expired")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "password reset token delete expired: get rows affected")
	}

	// Log how many tokens were deleted (in production, use proper logging)
	_ = rows

	return nil
}
