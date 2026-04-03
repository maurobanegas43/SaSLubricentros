package errors

import (
	"errors"
	"fmt"
	"net/http"
)

// Sentinel errors for domain-level validation and business rules.
var (
	ErrNotFound          = errors.New("resource not found")
	ErrAlreadyExists     = errors.New("resource already exists")
	ErrUnauthorized      = errors.New("unauthorized")
	ErrForbidden         = errors.New("forbidden")
	ErrInvalidInput      = errors.New("invalid input")
	ErrInternalServer    = errors.New("internal server error")
	ErrEmailAlreadyTaken = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrTokenExpired      = errors.New("token expired")
	ErrTokenRevoked      = errors.New("token revoked")
	ErrVehicleNotFound   = errors.New("vehicle not found")
	ErrAppointmentConflict = errors.New("appointment time slot conflict")
	ErrInsufficientStock = errors.New("insufficient product stock")
)

// DomainError wraps an error with an HTTP status code and a user-safe message.
type DomainError struct {
	Err        error
	StatusCode int
	Message    string
}

func (e *DomainError) Error() string {
	return e.Err.Error()
}

func (e *DomainError) Unwrap() error {
	return e.Err
}

// NewDomainError creates a new domain error.
func NewDomainError(err error, statusCode int, message string) *DomainError {
	return &DomainError{
		Err:        err,
		StatusCode: statusCode,
		Message:    message,
	}
}

// IsNotFound checks if the error is a not-found type.
func IsNotFound(err error) bool {
	var de *DomainError
	if errors.As(err, &de) {
		return de.StatusCode == http.StatusNotFound || errors.Is(de.Err, ErrNotFound)
	}
	return errors.Is(err, ErrNotFound)
}

// IsUnauthorized checks if the error is an unauthorized type.
func IsUnauthorized(err error) bool {
	var de *DomainError
	if errors.As(err, &de) {
		return de.StatusCode == http.StatusUnauthorized || errors.Is(de.Err, ErrUnauthorized)
	}
	return errors.Is(err, ErrUnauthorized)
}

// ConflictError creates a conflict domain error.
func ConflictError(msg string, args ...interface{}) *DomainError {
	return &DomainError{
		Err:        fmt.Errorf(msg, args...),
		StatusCode: http.StatusConflict,
		Message:    fmt.Sprintf(msg, args...),
	}
}

// ValidationError creates a validation domain error.
func ValidationError(msg string, args ...interface{}) *DomainError {
	return &DomainError{
		Err:        fmt.Errorf(msg, args...),
		StatusCode: http.StatusBadRequest,
		Message:    fmt.Sprintf(msg, args...),
	}
}
