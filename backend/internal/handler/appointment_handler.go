package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/lubricentros/api/internal/domain/entity"
	"github.com/lubricentros/api/internal/dto"
	"github.com/lubricentros/api/internal/middleware"
	"github.com/lubricentros/api/internal/repository"
	"github.com/lubricentros/api/internal/usecase"
	"github.com/lubricentros/api/pkg/response"
)

// AppointmentHandler handles appointment HTTP requests.
type AppointmentHandler struct {
	appointmentUsecase *usecase.AppointmentUsecase
}

// NewAppointmentHandler creates a new appointment handler.
func NewAppointmentHandler(appointmentUsecase *usecase.AppointmentUsecase) *AppointmentHandler {
	return &AppointmentHandler{appointmentUsecase: appointmentUsecase}
}

// List handles GET /appointments
func (h *AppointmentHandler) List(c *gin.Context) {
	userID := middleware.GetUserID(c)
	page, limit := parsePagination(c)
	offset := (page - 1) * limit

	appointments, err := h.appointmentUsecase.ListByUser(c.Request.Context(), userID, offset, limit)
	if err != nil {
		response.InternalError(c)
		return
	}

	responses := make([]dto.AppointmentResponse, len(appointments))
	for i, a := range appointments {
		responses[i] = appointmentToResponse(a)
	}

	response.Paginated(c, responses, int64(len(appointments)), offset, limit)
}

// GetByID handles GET /appointments/:id
func (h *AppointmentHandler) GetByID(c *gin.Context) {
	userID := middleware.GetUserID(c)
	appointmentID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid appointment ID")
		return
	}

	appointment, err := h.appointmentUsecase.GetAppointmentByID(c.Request.Context(), appointmentID, userID)
	if err != nil {
		response.NotFound(c, "Appointment not found")
		return
	}

	response.JSON(c, http.StatusOK, appointmentToResponse(*appointment))
}

// Create handles POST /appointments
func (h *AppointmentHandler) Create(c *gin.Context) {
	userID := middleware.GetUserID(c)

	var req dto.CreateAppointmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	fecha, err := time.Parse(time.RFC3339, req.Fecha)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid date format. Use RFC3339")
		return
	}

	tipoService := entity.AppointmentType(req.TipoService)

	appointment, err := h.appointmentUsecase.CreateAppointment(c.Request.Context(), usecase.CreateAppointmentInput{
		UserID:        userID,
		VehicleID:     req.VehicleID,
		Fecha:         fecha,
		TipoService:   tipoService,
		Observaciones: req.Observaciones,
	})
	if err != nil {
		if err == repository.ErrConflict {
			response.Error(c, http.StatusConflict, "Conflict", "Time slot is not available")
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, appointmentToResponse(*appointment))
}

// Update handles PUT /appointments/:id
func (h *AppointmentHandler) Update(c *gin.Context) {
	userID := middleware.GetUserID(c)
	appointmentID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid appointment ID")
		return
	}

	var req dto.UpdateAppointmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Validation(c, extractValidationErrors(err))
		return
	}

	input := usecase.UpdateAppointmentInput{
		AppointmentID: appointmentID,
		UserID:        userID,
	}

	if req.Fecha != "" {
		fecha, err := time.Parse(time.RFC3339, req.Fecha)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid date format. Use RFC3339")
			return
		}
		input.Fecha = &fecha
	}

	if req.TipoService != "" {
		tipo := entity.AppointmentType(req.TipoService)
		input.TipoService = &tipo
	}

	if req.Status != "" {
		status := entity.AppointmentStatus(req.Status)
		input.Status = &status
	}

	if req.Observaciones != "" {
		input.Observaciones = &req.Observaciones
	}

	appointment, err := h.appointmentUsecase.UpdateAppointment(c.Request.Context(), input)
	if err != nil {
		if err == repository.ErrInvalidInput {
			response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid status transition")
			return
		}
		if err == repository.ErrConflict {
			response.Error(c, http.StatusConflict, "Conflict", "Time slot is not available")
			return
		}
		response.NotFound(c, "Appointment not found")
		return
	}

	response.JSON(c, http.StatusOK, appointmentToResponse(*appointment))
}

// Delete handles DELETE /appointments/:id
func (h *AppointmentHandler) Delete(c *gin.Context) {
	userID := middleware.GetUserID(c)
	appointmentID, err := parseUintParam(c, "id")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid appointment ID")
		return
	}

	if err := h.appointmentUsecase.DeleteAppointment(c.Request.Context(), appointmentID, userID); err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", err.Error())
		return
	}

	response.NoContent(c)
}

// AvailableSlots handles GET /appointments/slots?date=YYYY-MM-DD
func (h *AppointmentHandler) AvailableSlots(c *gin.Context) {
	dateStr := c.Query("date")
	if dateStr == "" {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Date query parameter is required (format: YYYY-MM-DD)")
		return
	}

	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "Bad Request", "Invalid date format. Use YYYY-MM-DD")
		return
	}

	slots, err := h.appointmentUsecase.GetAvailableSlots(c.Request.Context(), date)
	if err != nil {
		response.InternalError(c)
		return
	}

	// Convert to string responses
	slotStrings := make([]string, len(slots))
	for i, s := range slots {
		slotStrings[i] = s.Format("15:04")
	}

	response.JSON(c, http.StatusOK, gin.H{
		"date":  dateStr,
		"slots": slotStrings,
	})
}

// appointmentToResponse converts an entity.Appointment to a DTO response.
func appointmentToResponse(a entity.Appointment) dto.AppointmentResponse {
	return dto.AppointmentResponse{
		ID:            a.ID,
		UserID:        a.UserID,
		VehicleID:     a.VehicleID,
		Fecha:         a.Fecha.Format("2006-01-02T15:04:05Z"),
		SlotEnd:       a.SlotEnd.Format("2006-01-02T15:04:05Z"),
		TipoService:   string(a.TipoService),
		Status:        string(a.Status),
		Observaciones: a.Observaciones,
		CreatedAt:     a.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:     a.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
}
