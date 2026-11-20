package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// UserRepositoryImpl is the MariaDB implementation of the UserRepository interface.
type UserRepositoryImpl struct {
	*BaseRepository
}

// NewUserRepository creates a new user repository.
func NewUserRepository(db *sql.DB) *UserRepositoryImpl {
	return &UserRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new user into the database.
func (r *UserRepositoryImpl) Create(ctx context.Context, user *entity.User) error {
	query := `INSERT INTO users (email, password_hash, name, phone, role, is_active, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	var id int64
	err := r.QueryRowContext(ctx, query,
		user.Email, user.PasswordHash, user.Name, user.Phone,
		user.Role, user.IsActive, user.CreatedAt, user.UpdatedAt,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "user create")
	}

	user.ID = uint(id)

	return nil
}

// GetByID retrieves a user by their ID.
func (r *UserRepositoryImpl) GetByID(ctx context.Context, id uint) (*entity.User, error) {
	query := `SELECT id, email, password_hash, name, phone, role, is_active, created_at, updated_at
		FROM users WHERE id = ?`

	var u entity.User
	err := r.QueryRowContext(ctx, query, id).Scan(
		&u.ID, &u.Email, &u.PasswordHash, &u.Name, &u.Phone,
		&u.Role, &u.IsActive, &u.CreatedAt, &u.UpdatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "user get by id")
	}

	return &u, nil
}

// GetByEmail retrieves a user by their email address.
func (r *UserRepositoryImpl) GetByEmail(ctx context.Context, email string) (*entity.User, error) {
	query := `SELECT id, email, password_hash, name, phone, role, is_active, created_at, updated_at
		FROM users WHERE email = ?`

	var u entity.User
	err := r.QueryRowContext(ctx, query, email).Scan(
		&u.ID, &u.Email, &u.PasswordHash, &u.Name, &u.Phone,
		&u.Role, &u.IsActive, &u.CreatedAt, &u.UpdatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "user get by email")
	}

	return &u, nil
}

// Update updates an existing user's information.
func (r *UserRepositoryImpl) Update(ctx context.Context, user *entity.User) error {
	query := `UPDATE users SET email = ?, name = ?, phone = ?, role = ?, is_active = ?, updated_at = ?
		WHERE id = ?`

	user.UpdatedAt = time.Now()

	result, err := r.ExecContext(ctx, query,
		user.Email, user.Name, user.Phone,
		user.Role, user.IsActive, user.UpdatedAt, user.ID,
	)
	if err != nil {
		return WrapError(err, "user update")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "user update: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "user update")
	}

	return nil
}

// Deactivate sets a user's is_active flag to false.
func (r *UserRepositoryImpl) Deactivate(ctx context.Context, id uint) error {
	query := `UPDATE users SET is_active = ?, updated_at = ? WHERE id = ?`

	result, err := r.ExecContext(ctx, query, false, time.Now(), id)
	if err != nil {
		return WrapError(err, "user deactivate")
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return WrapError(err, "user deactivate: get rows affected")
	}
	if rows == 0 {
		return WrapError(sql.ErrNoRows, "user deactivate")
	}

	return nil
}

// List returns a paginated list of users.
func (r *UserRepositoryImpl) List(ctx context.Context, offset, limit int) ([]entity.User, error) {
	query := `SELECT id, email, password_hash, name, phone, role, is_active, created_at, updated_at
		FROM users ORDER BY id DESC LIMIT ? OFFSET ?`

	rows, err := r.QueryContext(ctx, query, limit, offset)
	if err != nil {
		return nil, WrapError(err, "user list")
	}
	defer rows.Close()

	var users []entity.User
	for rows.Next() {
		var u entity.User
		if err := rows.Scan(
			&u.ID, &u.Email, &u.PasswordHash, &u.Name, &u.Phone,
			&u.Role, &u.IsActive, &u.CreatedAt, &u.UpdatedAt,
		); err != nil {
			return nil, WrapError(err, "user list: scan")
		}
		users = append(users, u)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "user list: iterate")
	}

	return users, nil
}

// Count returns the total number of users.
func (r *UserRepositoryImpl) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		return 0, WrapError(err, "user count")
	}
	return count, nil
}
