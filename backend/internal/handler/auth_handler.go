package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/dto"
	"github.com/lubricentros/api/internal/middleware"
	"github.com/lubricentros/api/internal/repository"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/response"
)

// AuthHandler handles authentication HTTP requests.
type AuthHandler struct {
	authUsecase *usecase.AuthUsecase
}

// NewAuthHandler creates a new auth handler.
func NewAuthHandler(authUsecase *usecase.AuthUsecase) *AuthHandler {
	return &AuthHandler{authUsecase: authUsecase}
}

// Register handles POST /auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	result, err := h.authUsecase.Register(c.Request.Context(), usecase.RegisterInput{
		Email:    req.Email,
		Password: req.Password,
		Name:     req.Name,
		Phone:    req.Phone,
	})
	if err != nil {
		if err == repository.ErrAlreadyExists {
			response.Error(c, http.StatusConflict, "Conflict", "Email already registered")
			return
		}
		if err == repository.ErrInvalidInput {
			response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid input data")
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, dto.TokenResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    900, // 15 minutes
	})
}

// Login handles POST /auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	result, err := h.authUsecase.Login(c.Request.Context(), usecase.LoginInput{
		Email:    req.Email,
		Password: req.Password,
	})
	if err != nil {
		if err == repository.ErrInvalidInput || err.Error() == "login: invalid credentials: invalid input" {
			response.Error(c, http.StatusUnauthorized, "Unauthorized", "Invalid email or password")
			return
		}
		response.InternalError(c)
		return
	}

	response.JSON(c, http.StatusOK, dto.TokenResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    900,
	})
}

// Refresh handles POST /auth/refresh
func (h *AuthHandler) Refresh(c *gin.Context) {
	var req dto.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	result, err := h.authUsecase.Refresh(c.Request.Context(), usecase.RefreshInput{
		RefreshToken: req.RefreshToken,
	})
	if err != nil {
		if err == repository.ErrInvalidInput {
			response.Error(c, http.StatusUnauthorized, "Unauthorized", "Invalid refresh token")
			return
		}
		response.InternalError(c)
		return
	}

	response.JSON(c, http.StatusOK, dto.TokenResponse{
		AccessToken:  result.AccessToken,
		RefreshToken: result.RefreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    900,
	})
}

// Logout handles POST /auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	var req dto.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	if err := h.authUsecase.Logout(c.Request.Context(), req.RefreshToken); err != nil {
		response.InternalError(c)
		return
	}

	response.NoContent(c)
}

// LogoutAll handles POST /auth/logout-all
func (h *AuthHandler) LogoutAll(c *gin.Context) {
	userID := middleware.GetUserID(c)

	if err := h.authUsecase.LogoutAll(c.Request.Context(), userID); err != nil {
		response.InternalError(c)
		return
	}

	response.NoContent(c)
}

// RequestPasswordRecovery handles POST /auth/password-recovery
func (h *AuthHandler) RequestPasswordRecovery(c *gin.Context) {
	var req dto.PasswordRecoveryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	if err := h.authUsecase.RequestPasswordRecovery(c.Request.Context(), usecase.PasswordRecoveryInput{
		Email: req.Email,
	}); err != nil {
		// Always return success to prevent email enumeration
		// Even if there's an error, we don't want to reveal if the email exists
		response.JSON(c, http.StatusOK, dto.MessageResponse{
			Message: "If the email exists, a password recovery link has been sent",
		})
		return
	}

	response.JSON(c, http.StatusOK, dto.MessageResponse{
		Message: "If the email exists, a password recovery link has been sent",
	})
}

// ResetPassword handles POST /auth/password-reset
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req dto.PasswordResetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	if err := h.authUsecase.ResetPassword(c.Request.Context(), usecase.PasswordResetInput{
		Token:       req.Token,
		NewPassword: req.NewPassword,
	}); err != nil {
		if err == repository.ErrInvalidInput {
			response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid or expired token")
			return
		}
		response.InternalError(c)
		return
	}

	response.JSON(c, http.StatusOK, dto.MessageResponse{
		Message: "Password has been reset successfully",
	})
}

// SearchUsers handles GET /users/search?q=query
func (h *AuthHandler) SearchUsers(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Query parameter 'q' is required")
		return
	}

	users, err := h.authUsecase.SearchUsers(c.Request.Context(), usecase.SearchUsersInput{
		Query: query,
	})
	if err != nil {
		response.InternalError(c)
		return
	}

	// Convert to response DTOs
	responses := make([]dto.UserResponse, len(users))
	for i, user := range users {
		responses[i] = dto.UserResponse{
			ID:        user.ID,
			Email:     user.Email,
			Name:      user.Name,
			Phone:     user.Phone,
			Role:      string(user.Role),
			IsActive:  user.IsActive,
			CreatedAt: user.CreatedAt.Format("2006-01-02T15:04:05Z"),
		}
	}

	response.JSON(c, http.StatusOK, dto.UserSearchResponse{
		Users: responses,
	})
}
