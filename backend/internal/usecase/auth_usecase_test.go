package usecase

import (
	"context"
	"testing"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// Mock repositories for testing
type mockUserRepo struct {
	users map[string]*entity.User
}

func (m *mockUserRepo) Create(ctx context.Context, user *entity.User) error {
	user.ID = uint(len(m.users) + 1)
	m.users[user.Email] = user
	return nil
}

func (m *mockUserRepo) GetByEmail(ctx context.Context, email string) (*entity.User, error) {
	if user, ok := m.users[email]; ok {
		return user, nil
	}
	return nil, nil
}

func (m *mockUserRepo) GetByID(ctx context.Context, id uint) (*entity.User, error) {
	for _, user := range m.users {
		if user.ID == id {
			return user, nil
		}
	}
	return nil, nil
}

func (m *mockUserRepo) Update(ctx context.Context, user *entity.User) error {
	if existing, ok := m.users[user.Email]; ok {
		existing.PasswordHash = user.PasswordHash
		existing.Name = user.Name
		existing.Phone = user.Phone
		existing.UpdatedAt = time.Now()
		return nil
	}
	return nil
}

func (m *mockUserRepo) Deactivate(ctx context.Context, id uint) error {
	return nil
}

func (m *mockUserRepo) List(ctx context.Context, offset, limit int) ([]entity.User, error) {
	return nil, nil
}

func (m *mockUserRepo) Count(ctx context.Context) (int64, error) {
	return int64(len(m.users)), nil
}

type mockPasswordResetRepo struct {
	tokens map[string]*entity.PasswordResetToken
}

func (m *mockPasswordResetRepo) Create(ctx context.Context, token *entity.PasswordResetToken) error {
	token.ID = uint(len(m.tokens) + 1)
	m.tokens[token.Token] = token
	return nil
}

func (m *mockPasswordResetRepo) GetByToken(ctx context.Context, token string) (*entity.PasswordResetToken, error) {
	if t, ok := m.tokens[token]; ok {
		return t, nil
	}
	return nil, nil
}

func (m *mockPasswordResetRepo) Delete(ctx context.Context, token string) error {
	delete(m.tokens, token)
	return nil
}

func (m *mockPasswordResetRepo) DeleteByUserID(ctx context.Context, userID uint) error {
	for token, t := range m.tokens {
		if t.UserID == userID {
			delete(m.tokens, token)
		}
	}
	return nil
}

func (m *mockPasswordResetRepo) DeleteExpired(ctx context.Context) error {
	for token, t := range m.tokens {
		if t.IsExpired() {
			delete(m.tokens, token)
		}
	}
	return nil
}

func TestRequestPasswordRecovery(t *testing.T) {
	userRepo := &mockUserRepo{
		users: make(map[string]*entity.User),
	}
	passwordResetRepo := &mockPasswordResetRepo{
		tokens: make(map[string]*entity.PasswordResetToken),
	}

	// Create a test user
	testUser := &entity.User{
		Email:        "test@example.com",
		PasswordHash: "hashed_password",
		Name:         "Test User",
		IsActive:     true,
	}
	userRepo.Create(context.Background(), testUser)

	uc := &AuthUsecase{
		userRepo:          userRepo,
		passwordResetRepo: passwordResetRepo,
	}

	t.Run("successful password recovery request", func(t *testing.T) {
		err := uc.RequestPasswordRecovery(context.Background(), PasswordRecoveryInput{
			Email: "test@example.com",
		})

		if err != nil {
			t.Errorf("Expected no error, got %v", err)
		}

		// Check that a token was created
		if len(passwordResetRepo.tokens) != 1 {
			t.Errorf("Expected 1 token, got %d", len(passwordResetRepo.tokens))
		}

		// Verify token properties
		for _, token := range passwordResetRepo.tokens {
			if token.UserID != testUser.ID {
				t.Errorf("Expected token for user %d, got %d", testUser.ID, token.UserID)
			}
			if token.ExpiresAt.Before(time.Now()) {
				t.Error("Token should not be expired immediately")
			}
			if token.ExpiresAt.After(time.Now().Add(2 * time.Hour)) {
				t.Error("Token expiration should be within 1 hour")
			}
		}
	})

	t.Run("password recovery for non-existent email returns success", func(t *testing.T) {
		// Clear tokens
		passwordResetRepo.tokens = make(map[string]*entity.PasswordResetToken)

		// Create a new usecase instance with the repo set
		ucWithRepo := &AuthUsecase{
			userRepo:          userRepo,
			passwordResetRepo: passwordResetRepo,
		}

		err := ucWithRepo.RequestPasswordRecovery(context.Background(), PasswordRecoveryInput{
			Email: "nonexistent@example.com",
		})

		// Should return success to prevent email enumeration
		if err != nil {
			t.Errorf("Expected no error for non-existent email, got %v", err)
		}

		// No token should be created
		if len(passwordResetRepo.tokens) != 0 {
			t.Errorf("Expected 0 tokens for non-existent email, got %d", len(passwordResetRepo.tokens))
		}
	})

	t.Run("password recovery with empty email fails", func(t *testing.T) {
		err := uc.RequestPasswordRecovery(context.Background(), PasswordRecoveryInput{
			Email: "",
		})

		if err == nil {
			t.Error("Expected error for empty email")
		}
	})
}

func TestResetPassword(t *testing.T) {
	userRepo := &mockUserRepo{
		users: make(map[string]*entity.User),
	}
	passwordResetRepo := &mockPasswordResetRepo{
		tokens: make(map[string]*entity.PasswordResetToken),
	}

	// Create a test user
	testUser := &entity.User{
		Email:        "test@example.com",
		PasswordHash: "old_hashed_password",
		Name:         "Test User",
		IsActive:     true,
	}
	userRepo.Create(context.Background(), testUser)

	// Create a valid token
	validToken := &entity.PasswordResetToken{
		UserID:    testUser.ID,
		Token:     "valid_token_123",
		ExpiresAt: time.Now().Add(1 * time.Hour),
	}
	passwordResetRepo.Create(context.Background(), validToken)

	// Create an expired token
	expiredToken := &entity.PasswordResetToken{
		UserID:    testUser.ID,
		Token:     "expired_token_456",
		ExpiresAt: time.Now().Add(-1 * time.Hour),
	}
	passwordResetRepo.Create(context.Background(), expiredToken)

	uc := &AuthUsecase{
		userRepo:          userRepo,
		passwordResetRepo: passwordResetRepo,
		refreshRepo:       nil, // Not needed for this test
	}

	t.Run("successful password reset", func(t *testing.T) {
		err := uc.ResetPassword(context.Background(), PasswordResetInput{
			Token:       "valid_token_123",
			NewPassword: "new_secure_password",
		})

		if err != nil {
			t.Errorf("Expected no error, got %v", err)
		}

		// Verify password was updated
		user, _ := userRepo.GetByEmail(context.Background(), "test@example.com")
		if user.PasswordHash == "old_hashed_password" {
			t.Error("Password should have been updated")
		}

		// Verify token was deleted
		if _, ok := passwordResetRepo.tokens["valid_token_123"]; ok {
			t.Error("Token should have been deleted after use")
		}
	})

	t.Run("password reset with expired token fails", func(t *testing.T) {
		err := uc.ResetPassword(context.Background(), PasswordResetInput{
			Token:       "expired_token_456",
			NewPassword: "new_secure_password",
		})

		if err == nil {
			t.Error("Expected error for expired token")
		}
	})

	t.Run("password reset with invalid token fails", func(t *testing.T) {
		err := uc.ResetPassword(context.Background(), PasswordResetInput{
			Token:       "invalid_token",
			NewPassword: "new_secure_password",
		})

		if err == nil {
			t.Error("Expected error for invalid token")
		}
	})

	t.Run("password reset with short password fails", func(t *testing.T) {
		// Create a new valid token
		newToken := &entity.PasswordResetToken{
			UserID:    testUser.ID,
			Token:     "new_valid_token",
			ExpiresAt: time.Now().Add(1 * time.Hour),
		}
		passwordResetRepo.Create(context.Background(), newToken)

		err := uc.ResetPassword(context.Background(), PasswordResetInput{
			Token:       "new_valid_token",
			NewPassword: "short",
		})

		if err == nil {
			t.Error("Expected error for short password")
		}
	})
}

func TestGenerateSecureToken(t *testing.T) {
	t.Run("generates token of correct length", func(t *testing.T) {
		token, err := generateSecureToken(32)
		if err != nil {
			t.Errorf("Expected no error, got %v", err)
		}

		// 32 bytes = 64 hex characters
		if len(token) != 64 {
			t.Errorf("Expected token length 64, got %d", len(token))
		}
	})

	t.Run("generates unique tokens", func(t *testing.T) {
		token1, _ := generateSecureToken(32)
		token2, _ := generateSecureToken(32)

		if token1 == token2 {
			t.Error("Expected unique tokens, got duplicates")
		}
	})
}
