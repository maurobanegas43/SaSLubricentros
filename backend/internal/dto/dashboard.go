package dto

// DashboardStatsResponse represents admin dashboard statistics.
type DashboardStatsResponse struct {
	TotalUsers            int64   `json:"total_users"`
	ActiveUsers           int64   `json:"active_users"`
	TotalVehicles         int64   `json:"total_vehicles"`
	TotalAppointments     int64   `json:"total_appointments"`
	PendingAppointments   int64   `json:"pending_appointments"`
	CompletedAppointments int64   `json:"completed_appointments"`
	TotalServices         int64   `json:"total_services"`
	TotalRevenue          float64 `json:"total_revenue"`
	LowStockProducts      int64   `json:"low_stock_products"`
}

// RevenueReportResponse represents revenue analytics.
type RevenueReportResponse struct {
	TotalRevenue  float64          `json:"total_revenue"`
	ByMonth       []MonthlyRevenue `json:"by_month"`
	ByServiceType []ServiceRevenue `json:"by_service_type"`
}

// MonthlyRevenue represents revenue for a specific month.
type MonthlyRevenue struct {
	Month   string  `json:"month"`
	Revenue float64 `json:"revenue"`
}

// ServiceRevenue represents revenue grouped by service type.
type ServiceRevenue struct {
	TipoAceite string  `json:"tipo_aceite"`
	Revenue    float64 `json:"revenue"`
	Count      int64   `json:"count"`
}

// ServiceStatsResponse represents service statistics.
type ServiceStatsResponse struct {
	TotalServices  int64            `json:"total_services"`
	ByOilType      []ServiceRevenue `json:"by_oil_type"`
	AverageKm      float64          `json:"average_km"`
	TotalPartsUsed int64            `json:"total_parts_used"`
}

// UserAnalyticsResponse represents user activity analytics.
type UserAnalyticsResponse struct {
	TotalUsers         int64              `json:"total_users"`
	ActiveLast30Days   int64              `json:"active_last_30_days"`
	NewLast30Days      int64              `json:"new_last_30_days"`
	TopUsersByVehicles []UserVehicleCount `json:"top_users_by_vehicles"`
}

// UserVehicleCount represents user vehicle count.
type UserVehicleCount struct {
	UserID       uint   `json:"user_id"`
	UserName     string `json:"user_name"`
	VehicleCount int64  `json:"vehicle_count"`
}
