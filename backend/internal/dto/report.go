package dto

// ReportRequest represents a request for generating reports.
type ReportRequest struct {
	StartDate string `json:"start_date,omitempty"` // RFC3339
	EndDate   string `json:"end_date,omitempty"`   // RFC3339
}

// InvoiceRequest represents a request for generating an invoice.
type InvoiceRequest struct {
	ServiceID uint `json:"service_id" validate:"required"`
}
