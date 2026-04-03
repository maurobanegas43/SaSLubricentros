package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// SuccessResponse is the standard success envelope.
type SuccessResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data"`
}

// ErrorResponse is the standard error envelope.
type ErrorResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
	Message string `json:"message,omitempty"`
}

// ValidationErrorResponse is returned when input validation fails.
type ValidationErrorResponse struct {
	Success bool            `json:"success"`
	Error   string          `json:"error"`
	Fields  map[string]string `json:"fields,omitempty"`
}

// PaginatedResponse wraps paginated data.
type PaginatedResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data"`
	Meta    PaginationMeta `json:"meta"`
}

// PaginationMeta contains pagination metadata.
type PaginationMeta struct {
	Total    int64 `json:"total"`
	Offset   int   `json:"offset"`
	Limit    int   `json:"limit"`
	HasMore  bool  `json:"has_more"`
}

// JSON sends a standardized success response.
func JSON(c *gin.Context, statusCode int, data interface{}) {
	c.JSON(statusCode, SuccessResponse{
		Success: true,
		Data:    data,
	})
}

// Error sends a standardized error response.
func Error(c *gin.Context, statusCode int, err string, message string) {
	c.JSON(statusCode, ErrorResponse{
		Success: false,
		Error:   err,
		Message: message,
	})
}

// Validation sends a validation error response with field-level details.
func Validation(c *gin.Context, fields map[string]string) {
	c.JSON(http.StatusBadRequest, ValidationErrorResponse{
		Success: false,
		Error:   "Validation Error",
		Fields:  fields,
	})
}

// Paginated sends a paginated response.
func Paginated(c *gin.Context, data interface{}, total int64, offset, limit int) {
	c.JSON(http.StatusOK, PaginatedResponse{
		Success: true,
		Data:    data,
		Meta: PaginationMeta{
			Total:   total,
			Offset:  offset,
			Limit:   limit,
			HasMore: int64(offset+limit) < total,
		},
	})
}

// Created sends a 201 response with the created resource.
func Created(c *gin.Context, data interface{}) {
	JSON(c, http.StatusCreated, data)
}

// NoContent sends a 204 response.
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// NotFound sends a 404 response.
func NotFound(c *gin.Context, message string) {
	Error(c, http.StatusNotFound, "Not Found", message)
}

// Unauthorized sends a 401 response.
func Unauthorized(c *gin.Context, message string) {
	Error(c, http.StatusUnauthorized, "Unauthorized", message)
}

// Forbidden sends a 403 response.
func Forbidden(c *gin.Context, message string) {
	Error(c, http.StatusForbidden, "Forbidden", message)
}

// InternalError sends a 500 response with a generic message.
func InternalError(c *gin.Context) {
	Error(c, http.StatusInternalServerError, "Internal Server Error", "An unexpected error occurred")
}
