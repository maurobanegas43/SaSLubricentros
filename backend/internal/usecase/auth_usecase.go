package usecase

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
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
	userRepo          domainrepo.UserRepository
	refreshRepo       domainrepo.RefreshTokenRepository
	auditRepo         domainrepo.AuditLogRepository
	passwordResetRepo domainrepo.PasswordResetTokenRepository
	jwtMgr            *jwtpkg.Manager
}

// NewAuthUsecase creates a new auth usecase.
func NewAuthUsecase(
	userRepo domainrepo.UserRepository,
	refreshRepo domainrepo.RefreshTokenRepository,
	jwtMgr *jwtpkg.Manager,
) *AuthUsecase {
	return &AuthUsecase{
		userRepo:          userRepo,
		refreshRepo:       refreshRepo,
		auditRepo:         nil, // Will be set later to avoid circular dependency
		passwordResetRepo: nil, // Will be set later to avoid circular dependency
		jwtMgr:            jwtMgr,
	}
}

// SetAuditRepo sets the audit repository (to avoid circular dependency)
func (uc *AuthUsecase) SetAuditRepo(auditRepo domainrepo.AuditLogRepository) {
	uc.auditRepo = auditRepo
}

// SetPasswordResetRepo sets the password reset repository (to avoid circular dependency)
func (uc *AuthUsecase) SetPasswordResetRepo(passwordResetRepo domainrepo.PasswordResetTokenRepository) {
	uc.passwordResetRepo = passwordResetRepo
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
	ipAddress := getIPFromContext(ctx)

	// Validate input
	if input.Email == "" {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "empty email")
		return nil, repository.ErrInvalidInput
	}
	if len(input.Password) < 8 {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "password too short")
		return nil, repository.ErrInvalidInput
	}
	if input.Name == "" {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "empty name")
		return nil, repository.ErrInvalidInput
	}

	// Check if email already exists
	existing, err := uc.userRepo.GetByEmail(ctx, input.Email)
	if err == nil && existing != nil {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "email already exists")
		return nil, repository.ErrAlreadyExists
	}

	// Hash password
	pwHash, err := hash.HashPassword(input.Password)
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "password hashing failed")
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
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "user creation failed")
		return nil, fmt.Errorf("register: create user: %w", err)
	}

	// Generate tokens
	accessToken, err := uc.jwtMgr.GenerateAccessToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "token generation failed")
		return nil, fmt.Errorf("register: generate access token: %w", err)
	}

	refreshToken, err := uc.jwtMgr.GenerateRefreshToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "refresh token generation failed")
		return nil, fmt.Errorf("register: generate refresh token: %w", err)
	}

	// Save refresh token
	if err := uc.saveRefreshToken(ctx, user.ID, refreshToken); err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, false, "refresh token save failed")
		return nil, fmt.Errorf("register: save refresh token: %w", err)
	}

	// Log successful registration
	uc.logAuthEvent(ctx, entity.AuthEventRegistration, input.Email, ipAddress, true, "")

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
	ipAddress := getIPFromContext(ctx)

	// Find user by email
	user, err := uc.userRepo.GetByEmail(ctx, input.Email)
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventLogin, input.Email, ipAddress, false, "user not found")
		return nil, fmt.Errorf("login: %w", err)
	}

	// Check if user is active
	if !user.IsActive {
		uc.logAuthEvent(ctx, entity.AuthEventLogin, input.Email, ipAddress, false, "user inactive")
		return nil, fmt.Errorf("login: %w", repository.ErrInvalidInput)
	}

	// Verify password
	if err := hash.CheckPassword(input.Password, user.PasswordHash); err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventLogin, input.Email, ipAddress, false, "invalid password")
		return nil, fmt.Errorf("login: invalid credentials: %w", repository.ErrInvalidInput)
	}

	// Generate tokens
	accessToken, err := uc.jwtMgr.GenerateAccessToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventLogin, input.Email, ipAddress, false, "token generation failed")
		return nil, fmt.Errorf("login: generate access token: %w", err)
	}

	refreshToken, err := uc.jwtMgr.GenerateRefreshToken(user.ID, user.Email, user.Role.String())
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventLogin, input.Email, ipAddress, false, "refresh token generation failed")
		return nil, fmt.Errorf("login: generate refresh token: %w", err)
	}

	// Save refresh token
	if err := uc.saveRefreshToken(ctx, user.ID, refreshToken); err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventLogin, input.Email, ipAddress, false, "refresh token save failed")
		return nil, fmt.Errorf("login: save refresh token: %w", err)
	}

	// Log successful login
	uc.logAuthEvent(ctx, entity.AuthEventLogin, input.Email, ipAddress, true, "")

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


// logAuthEvent logs an authentication event to the audit log
func (uc *AuthUsecase) logAuthEvent(ctx context.Context, eventType entity.AuthEventType, email string, ipAddress string, success bool, errorMsg string) {
	if uc.auditRepo == nil {
		return // Audit logging not configured
	}

	var errPtr *string
	if errorMsg != "" {
		errPtr = &errorMsg
	}

	log := &entity.AuthAuditLog{
		EventType:    eventType,
		Email:        &email,
		IPAddress:    ipAddress,
		Success:      success,
		ErrorMessage: errPtr,
	}

	// Log asynchronously to avoid blocking the main flow
	go func() {
		if err := uc.auditRepo.CreateAuthEvent(context.Background(), log); err != nil {
			// In production, this should be logged to a monitoring system
			fmt.Printf("Failed to log auth event: %v\n", err)
		}
	}()
}

// getIPFromContext extracts IP address from context (if available)
func getIPFromContext(ctx context.Context) string {
	// This is a placeholder - in production, extract from Gin context
	return "unknown"
}


// PasswordRecoveryInput holds the input for password recovery request
type PasswordRecoveryInput struct {
	Email string
}

// RequestPasswordRecovery generates a password reset token and sends recovery email
func (uc *AuthUsecase) RequestPasswordRecovery(ctx context.Context, input PasswordRecoveryInput) error {
	ipAddress := getIPFromContext(ctx)

	// Validate email format
	if input.Email == "" {
		uc.logAuthEvent(ctx, entity.AuthEventPasswordRecovery, input.Email, ipAddress, false, "empty email")
		return repository.ErrInvalidInput
	}

	// Check if user exists
	user, err := uc.userRepo.GetByEmail(ctx, input.Email)
	if err != nil || user == nil {
		// Don't reveal if email exists - return success anyway (timing attack prevention)
		uc.logAuthEvent(ctx, entity.AuthEventPasswordRecovery, input.Email, ipAddress, false, "user not found")
		return nil
	}

	// Check if user is active
	if !user.IsActive {
		// Don't reveal if user is inactive - return success anyway
		uc.logAuthEvent(ctx, entity.AuthEventPasswordRecovery, input.Email, ipAddress, false, "user inactive")
		return nil
	}

	// Delete any existing password reset tokens for this user
	if uc.passwordResetRepo != nil {
		_ = uc.passwordResetRepo.DeleteByUserID(ctx, user.ID)
	}

	// Generate cryptographically secure random token (32 bytes = 64 hex chars)
	token, err := generateSecureToken(32)
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventPasswordRecovery, input.Email, ipAddress, false, "token generation failed")
		return fmt.Errorf("password recovery: generate token: %w", err)
	}

	// Create password reset token with 1 hour expiration
	resetToken := &entity.PasswordResetToken{
		UserID:    user.ID,
		Token:     token,
		ExpiresAt: time.Now().Add(1 * time.Hour),
	}

	if uc.passwordResetRepo != nil {
		if err := uc.passwordResetRepo.Create(ctx, resetToken); err != nil {
			uc.logAuthEvent(ctx, entity.AuthEventPasswordRecovery, input.Email, ipAddress, false, "token save failed")
			return fmt.Errorf("password recovery: save token: %w", err)
		}
	}

	// TODO: Send recovery email with token
	// For now, just log the token (in production, this should send an email)
	fmt.Printf("[PASSWORD RECOVERY] Token for %s: %s (expires in 1 hour)\n", input.Email, token)

	// Log successful password recovery request
	uc.logAuthEvent(ctx, entity.AuthEventPasswordRecovery, input.Email, ipAddress, true, "")

	return nil
}

// PasswordResetInput holds the input for password reset
type PasswordResetInput struct {
	Token       string
	NewPassword string
}

// ResetPassword validates the token and resets the user's password
func (uc *AuthUsecase) ResetPassword(ctx context.Context, input PasswordResetInput) error {
	ipAddress := getIPFromContext(ctx)

	// Validate input
	if input.Token == "" {
		return repository.ErrInvalidInput
	}
	if len(input.NewPassword) < 8 {
		return repository.ErrInvalidInput
	}

	// Get token from database
	if uc.passwordResetRepo == nil {
		return fmt.Errorf("password reset: repository not configured")
	}

	resetToken, err := uc.passwordResetRepo.GetByToken(ctx, input.Token)
	if err != nil || resetToken == nil {
		uc.logAuthEvent(ctx, entity.AuthEventPasswordReset, "", ipAddress, false, "invalid token")
		return fmt.Errorf("password reset: invalid token: %w", repository.ErrInvalidInput)
	}

	// Check if token is expired
	if resetToken.IsExpired() {
		uc.logAuthEvent(ctx, entity.AuthEventPasswordReset, "", ipAddress, false, "token expired")
		return fmt.Errorf("password reset: token expired: %w", repository.ErrInvalidInput)
	}

	// Get user
	user, err := uc.userRepo.GetByID(ctx, resetToken.UserID)
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventPasswordReset, "", ipAddress, false, "user not found")
		return fmt.Errorf("password reset: user not found: %w", err)
	}

	// Hash new password
	pwHash, err := hash.HashPassword(input.NewPassword)
	if err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventPasswordReset, user.Email, ipAddress, false, "password hashing failed")
		return fmt.Errorf("password reset: hash password: %w", err)
	}

	// Update user password
	user.PasswordHash = pwHash
	if err := uc.userRepo.Update(ctx, user); err != nil {
		uc.logAuthEvent(ctx, entity.AuthEventPasswordReset, user.Email, ipAddress, false, "password update failed")
		return fmt.Errorf("password reset: update password: %w", err)
	}

	// Delete the used token
	if err := uc.passwordResetRepo.Delete(ctx, input.Token); err != nil {
		// Log but don't fail - password was already reset
		fmt.Printf("[PASSWORD RESET] Failed to delete token: %v\n", err)
	}

	// Revoke all refresh tokens for security (force re-login)
	if uc.refreshRepo != nil {
		if err := uc.refreshRepo.RevokeAllByUserID(ctx, user.ID); err != nil {
			// Log but don't fail
			fmt.Printf("[PASSWORD RESET] Failed to revoke refresh tokens: %v\n", err)
		}
	}

	// Log successful password reset
	uc.logAuthEvent(ctx, entity.AuthEventPasswordReset, user.Email, ipAddress, true, "")

	return nil
}

// generateSecureToken generates a cryptographically secure random token
func generateSecureToken(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}
