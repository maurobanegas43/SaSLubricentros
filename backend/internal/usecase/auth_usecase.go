package usecase

import (
	"context"
	"crypto/sha256"
	"fmt"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
	domainrepo "github.com/lubricentros/api/internal/domain/repository"
	"github.com/lubricentros/api/internal/repository"
	"github.com/lubricentros/api/pkg/hash"
	jwtpkg "github.com/lubricentros/api/pkg/jwt"
)

// AuthUsecase handles authentication business logic.
type AuthUsecase struct {
	userRepo    domainrepo.UserRepository
	refreshRepo domainrepo.RefreshTokenRepository
	jwtMgr      *jwtpkg.Manager
}

// NewAuthUsecase creates a new auth usecase.
func NewAuthUsecase(
	userRepo domainrepo.UserRepository,
	refreshRepo domainrepo.RefreshTokenRepository,
	jwtMgr *jwtpkg.Manager,
) *AuthUsecase {
	return &AuthUsecase{
		userRepo:    userRepo,
		refreshRepo: refreshRepo,
		jwtMgr:      jwtMgr,
	}
}

// RegisterInput holds the input for user registration.
type RegisterInput struct {
	Email    string
	Password string
	Name     string
	Phone    string
}

// RegisterResult holds the output of a successful registration.
type RegisterResult struct {
	User         *entity.User
	AccessToken  string
	RefreshToken string
}

// Register validates input, hashes password, creates user, and generates tokens.
func (uc *AuthUsecase) Register(ctx context.Context, input RegisterInput) (*RegisterResult, error) {
	// Validate input
	if input.Email == "" {
		return nil, repository.ErrInvalidInput
	}
	if len(input.Password) < 8 {
		return nil, repository.ErrInvalidInput
	}
	if input.Name == "" {
		return nil, repository.ErrInvalidInput
	}

	// Check if email already exists
	existing, err := uc.userRepo.GetByEmail(ctx, input.Email)
	if err == nil && existing != nil {
		return nil, repository.ErrAlreadyExists
	}

	// Hash password
	pwHash, err := hash.HashPassword(input.Password)
	if err != nil {
		return nil, fmt.Errorf("register: hash password: %w", err)
	}

	// Create user
	user := &entity.User{
		Email:        input.Email,
		PasswordHash: pwHash,
		Name:         input.Name,
		Phone:        input.Phone,
		Role:         entity.RoleCustomer,
		IsActive:     true,
	}

	if err := uc.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("register: create user: %w", err)
	}

	// Generate tokens
	accessToken, err := uc.jwtMgr.GenerateAccessToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		return nil, fmt.Errorf("register: generate access token: %w", err)
	}

	refreshToken, err := uc.jwtMgr.GenerateRefreshToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		return nil, fmt.Errorf("register: generate refresh token: %w", err)
	}

	// Save refresh token
	if err := uc.saveRefreshToken(ctx, user.ID, refreshToken); err != nil {
		return nil, fmt.Errorf("register: save refresh token: %w", err)
	}

	return &RegisterResult{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// LoginInput holds the input for user login.
type LoginInput struct {
	Email    string
	Password string
}

// LoginResult holds the output of a successful login.
type LoginResult struct {
	User         *entity.User
	AccessToken  string
	RefreshToken string
}

// Login finds user by email, checks password, generates tokens, and saves refresh token.
func (uc *AuthUsecase) Login(ctx context.Context, input LoginInput) (*LoginResult, error) {
	// Find user by email
	user, err := uc.userRepo.GetByEmail(ctx, input.Email)
	if err != nil {
		return nil, fmt.Errorf("login: %w", err)
	}

	// Check if user is active
	if !user.IsActive {
		return nil, fmt.Errorf("login: %w", repository.ErrInvalidInput)
	}

	// Verify password
	if err := hash.CheckPassword(input.Password, user.PasswordHash); err != nil {
		return nil, fmt.Errorf("login: invalid credentials: %w", repository.ErrInvalidInput)
	}

	// Generate tokens
	accessToken, err := uc.jwtMgr.GenerateAccessToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		return nil, fmt.Errorf("login: generate access token: %w", err)
	}

	refreshToken, err := uc.jwtMgr.GenerateRefreshToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		return nil, fmt.Errorf("login: generate refresh token: %w", err)
	}

	// Save refresh token
	if err := uc.saveRefreshToken(ctx, user.ID, refreshToken); err != nil {
		return nil, fmt.Errorf("login: save refresh token: %w", err)
	}

	return &LoginResult{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// RefreshInput holds the input for token refresh.
type RefreshInput struct {
	RefreshToken string
}

// RefreshResult holds the output of a successful token refresh.
type RefreshResult struct {
	AccessToken  string
	RefreshToken string
}

// Refresh validates the refresh token, checks it's not revoked, generates new tokens,
// revokes the old token, and saves the new one (rotation).
func (uc *AuthUsecase) Refresh(ctx context.Context, input RefreshInput) (*RefreshResult, error) {
	// Validate the JWT refresh token
	claims, err := uc.jwtMgr.ValidateRefreshToken(input.RefreshToken)
	if err != nil {
		return nil, fmt.Errorf("refresh: invalid token: %w", repository.ErrInvalidInput)
	}

	// Hash the token to look it up in the database
	tokenHash := hashToken(input.RefreshToken)

	// Check if token exists and is not revoked
	stored, err := uc.refreshRepo.GetByTokenHash(ctx, tokenHash)
	if err != nil {
		return nil, fmt.Errorf("refresh: %w", err)
	}

	if stored.RevokedAt != nil {
		return nil, fmt.Errorf("refresh: token revoked: %w", repository.ErrInvalidInput)
	}

	// Generate new tokens
	accessToken, err := uc.jwtMgr.GenerateAccessToken(claims.UserID, claims.Email, claims.Role)
	if err != nil {
		return nil, fmt.Errorf("refresh: generate access token: %w", err)
	}

	newRefreshToken, err := uc.jwtMgr.GenerateRefreshToken(claims.UserID, claims.Email, claims.Role)
	if err != nil {
		return nil, fmt.Errorf("refresh: generate refresh token: %w", err)
	}

	// Revoke old token
	if err := uc.refreshRepo.Revoke(ctx, tokenHash); err != nil {
		return nil, fmt.Errorf("refresh: revoke old token: %w", err)
	}

	// Save new refresh token
	if err := uc.saveRefreshToken(ctx, claims.UserID, newRefreshToken); err != nil {
		return nil, fmt.Errorf("refresh: save new refresh token: %w", err)
	}

	return &RefreshResult{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
	}, nil
}

// Logout revokes a refresh token.
func (uc *AuthUsecase) Logout(ctx context.Context, refreshToken string) error {
	tokenHash := hashToken(refreshToken)

	if err := uc.refreshRepo.Revoke(ctx, tokenHash); err != nil {
		return fmt.Errorf("logout: revoke token: %w", err)
	}

	return nil
}

// LogoutAll revokes all refresh tokens for a user.
func (uc *AuthUsecase) LogoutAll(ctx context.Context, userID uint) error {
	if err := uc.refreshRepo.RevokeAllByUserID(ctx, userID); err != nil {
		return fmt.Errorf("logout all: revoke all tokens: %w", err)
	}

	return nil
}

// saveRefreshToken hashes the token and stores it in the database.
func (uc *AuthUsecase) saveRefreshToken(ctx context.Context, userID uint, token string) error {
	tokenHash := hashToken(token)

	rt := &entity.RefreshToken{
		UserID:    userID,
		TokenHash: tokenHash,
		ExpiresAt: time.Now().Add(uc.jwtMgr.RefreshExpiry()),
	}

	return uc.refreshRepo.Create(ctx, rt)
}

// hashToken creates a SHA-256 hash of the token for storage.
func hashToken(token string) string {
	h := sha256.Sum256([]byte(token))
	return fmt.Sprintf("%x", h)
}
