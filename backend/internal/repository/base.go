package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
)

// Common sentinel errors used across all repository implementations.
var (
	// ErrNotFound is returned when a requested resource does not exist.
	ErrNotFound = errors.New("resource not found")

	// ErrAlreadyExists is returned when a resource with the same unique key already exists.
	ErrAlreadyExists = errors.New("resource already exists")

	// ErrConflict is returned when an operation conflicts with current state.
	ErrConflict = errors.New("operation conflict")

	// ErrInvalidInput is returned when input data fails validation.
	ErrInvalidInput = errors.New("invalid input")
)

// Pagination holds the parameters for paginated queries.
type Pagination struct {
	Offset int `json:"offset"`
	Limit  int `json:"limit"`
}

// NewPagination creates a Pagination with validated defaults.
// If limit is <= 0, it defaults to 20. If offset is < 0, it defaults to 0.
func NewPagination(offset, limit int) Pagination {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100 // Hard ceiling to prevent abuse
	}
	if offset < 0 {
		offset = 0
	}
	return Pagination{Offset: offset, Limit: limit}
}

// PaginatedResult wraps a query result set with pagination metadata.
type PaginatedResult[T any] struct {
	Items   []T   `json:"items"`
	Total   int64 `json:"total"`
	Offset  int   `json:"offset"`
	Limit   int   `json:"limit"`
	HasMore bool  `json:"has_more"`
}

// HasNext returns true if there are more results beyond the current page.
func (p PaginatedResult[T]) HasNext() bool {
	return p.HasMore
}

// BaseRepository provides a shared foundation for all repository implementations.
type BaseRepository struct {
	DB *sql.DB
}

// NewBaseRepository creates a new BaseRepository with the given database connection.
func NewBaseRepository(db *sql.DB) *BaseRepository {
	return &BaseRepository{DB: db}
}

// ExecContext executes a query after converting generic "?" placeholders
// to PostgreSQL positional placeholders ($1, $2, ...).
func (r *BaseRepository) ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error) {
	return r.DB.ExecContext(ctx, rebindPostgres(query), args...)
}

// QueryContext runs a query that returns rows after rebinding placeholders.
func (r *BaseRepository) QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error) {
	return r.DB.QueryContext(ctx, rebindPostgres(query), args...)
}

// QueryRowContext runs a query that is expected to return at most one row,
// after rebinding placeholders.
func (r *BaseRepository) QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row {
	return r.DB.QueryRowContext(ctx, rebindPostgres(query), args...)
}

// rebindPostgres converts "?" placeholders into PostgreSQL style "$n".
// It ignores placeholders inside single or double quoted strings.
func rebindPostgres(query string) string {
	var b strings.Builder
	b.Grow(len(query) + 8)

	argPos := 1
	inSingle := false
	inDouble := false

	for i := 0; i < len(query); i++ {
		ch := query[i]

		// Handle escaped single quote in SQL string literals ('')
		if inSingle && ch == '\'' && i+1 < len(query) && query[i+1] == '\'' {
			b.WriteByte(ch)
			b.WriteByte(query[i+1])
			i++
			continue
		}

		if !inDouble && ch == '\'' {
			inSingle = !inSingle
			b.WriteByte(ch)
			continue
		}
		if !inSingle && ch == '"' {
			inDouble = !inDouble
			b.WriteByte(ch)
			continue
		}

		if ch == '?' && !inSingle && !inDouble {
			b.WriteString(fmt.Sprintf("$%d", argPos))
			argPos++
			continue
		}

		b.WriteByte(ch)
	}

	return b.String()
}

// WrapError translates low-level database errors into domain-level sentinel errors.
// It should be called on every query error before returning to the caller.
func WrapError(err error, operation string) error {
	if err == nil {
		return nil
	}

	if errors.Is(err, sql.ErrNoRows) {
		return fmt.Errorf("%s: %w", operation, ErrNotFound)
	}

	// MySQL duplicate key errors (error codes 1062, 1586)
	var mysqlErr interface{ Error() string }
	if errors.As(err, &mysqlErr) {
		// Check for duplicate entry message pattern
		errStr := mysqlErr.Error()
		if len(errStr) > 0 && (contains(errStr, "Duplicate entry") || contains(errStr, "1062")) {
			return fmt.Errorf("%s: %w", operation, ErrAlreadyExists)
		}
	}

	return fmt.Errorf("%s: %w", operation, err)
}

// contains is a simple substring check to avoid importing strings in this file.
func contains(s, substr string) bool {
	return len(s) >= len(substr) && searchSubstring(s, substr)
}

func searchSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
