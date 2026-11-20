package hash

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

// HashPassword generates a bcrypt hash from a plaintext password.
// Uses DefaultCost (10) which is suitable for most applications.
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("hash password: %w", err)
	}
	return string(bytes), nil
}

// CheckPassword compares a plaintext password against a bcrypt hash.
// Returns nil if the password matches, error otherwise.
func CheckPassword(password, hash string) error {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
}
