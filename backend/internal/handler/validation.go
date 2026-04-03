package handler

import (
	"github.com/go-playground/validator/v10"
)

// extractValidationErrors converts validator errors into a map of field -> message.
func extractValidationErrors(err error) map[string]string {
	if ve, ok := err.(validator.ValidationErrors); ok {
		fields := make(map[string]string)
		for _, fe := range ve {
			fields[fe.Field()] = formatValidationError(fe)
		}
		return fields
	}
	return nil
}

// formatValidationError returns a human-readable message for a validation error.
func formatValidationError(fe validator.FieldError) string {
	switch fe.Tag() {
	case "required":
		return fe.Field() + " is required"
	case "email":
		return fe.Field() + " must be a valid email address"
	case "min":
		return fe.Field() + " must be at least " + fe.Param() + " characters"
	case "max":
		return fe.Field() + " must be at most " + fe.Param() + " characters"
	case "oneof":
		return fe.Field() + " must be one of: " + fe.Param()
	default:
		return fe.Field() + " failed validation on " + fe.Tag()
	}
}
