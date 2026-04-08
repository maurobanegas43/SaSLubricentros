package pdf

import (
	"bytes"
	"fmt"
	"time"

	"github.com/jung-kurt/gofpdf"
	"github.com/lubricentros/api/internal/domain/entity"
)

// VehicleReportGenerator generates PDF reports for vehicles.
type VehicleReportGenerator struct{}

// NewVehicleReportGenerator creates a new vehicle report generator.
func NewVehicleReportGenerator() *VehicleReportGenerator {
	return &VehicleReportGenerator{}
}

// GenerateVehicleServiceReport generates a PDF report for vehicle service history.
func (g *VehicleReportGenerator) GenerateVehicleServiceReport(
	vehicle *entity.Vehicle,
	services []entity.ServiceRecord,
	addendums map[uint][]entity.ServiceAddendum,
) ([]byte, error) {

	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.AddPage()

	// Title
	pdf.SetFont("Arial", "B", 16)
	pdf.Cell(190, 10, "Reporte de Servicio del Vehiculo")
	pdf.Ln(12)

	// Vehicle Information
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 8, "Informacion del Vehiculo")
	pdf.Ln(6)

	pdf.SetFont("Arial", "", 10)
	pdf.Cell(40, 6, "Patente:")
	pdf.Cell(60, 6, vehicle.Patente)
	pdf.Ln(6)

	pdf.Cell(40, 6, "Marca/Modelo:")
	pdf.Cell(60, 6, fmt.Sprintf("%s %s", vehicle.Marca, vehicle.Modelo))
	pdf.Ln(6)

	pdf.Cell(40, 6, "Anio:")
	pdf.Cell(60, 6, fmt.Sprintf("%d", vehicle.Anio))
	pdf.Ln(6)

	pdf.Cell(40, 6, "Kilometraje Actual:")
	pdf.Cell(60, 6, fmt.Sprintf("%d km", vehicle.KmActual))
	pdf.Ln(10)

	// Service History
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 8, "Historial de Servicios")
	pdf.Ln(6)

	if len(services) == 0 {
		pdf.SetFont("Arial", "", 10)
		pdf.Cell(190, 6, "No hay servicios registrados.")
		pdf.Ln(10)
	} else {
		// Table Header
		pdf.SetFont("Arial", "B", 8)
		pdf.Cell(30, 7, "Fecha")
		pdf.Cell(25, 7, "Kilometros")
		pdf.Cell(40, 7, "Tipo de Aceite")
		pdf.Cell(45, 7, "Marca Aceite")
		pdf.Cell(25, 7, "Costo")
		pdf.Cell(25, 7, "Prox.Service")
		pdf.Ln(7)

		// Table Rows
		pdf.SetFont("Arial", "", 8)
		for _, svc := range services {
			pdf.Cell(30, 6, svc.Fecha.Format("02/01/2006"))
			pdf.Cell(25, 6, fmt.Sprintf("%d km", svc.Km))
			pdf.Cell(40, 6, string(svc.TipoAceite))
			pdf.Cell(45, 6, svc.MarcaAceite)

			if svc.CostoTotal != nil {
				pdf.Cell(25, 6, fmt.Sprintf("$%.2f", *svc.CostoTotal))
			} else {
				pdf.Cell(25, 6, "-")
			}

			if svc.ProximoServiceKm != nil {
				pdf.Cell(25, 6, fmt.Sprintf("%d km", *svc.ProximoServiceKm))
			} else {
				pdf.Cell(25, 6, "-")
			}
			pdf.Ln(6)

			// Add addendums if any
			if addendums != nil {
				if adds, ok := addendums[svc.ID]; ok {
					for _, add := range adds {
						pdf.SetFont("Arial", "I", 7)
						pdf.Cell(10, 5, "  ->")
						pdf.Cell(180, 5, fmt.Sprintf("Correccion: %s", add.Reason))
						pdf.Ln(5)
					}
					pdf.SetFont("Arial", "", 8)
				}
			}
		}
	}

	// Summary
	pdf.Ln(10)
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 8, "Resumen")
	pdf.Ln(6)

	pdf.SetFont("Arial", "", 10)
	pdf.Cell(40, 6, "Total de Servicios:")
	pdf.Cell(60, 6, fmt.Sprintf("%d", len(services)))
	pdf.Ln(6)

	var totalCost float64
	for _, svc := range services {
		if svc.CostoTotal != nil {
			totalCost += *svc.CostoTotal
		}
	}
	pdf.Cell(40, 6, "Costo Total:")
	pdf.Cell(60, 6, fmt.Sprintf("$%.2f", totalCost))
	pdf.Ln(15)

	// Footer
	pdf.SetFont("Arial", "I", 8)
	pdf.Cell(190, 6, fmt.Sprintf("Reporte generado el %s", time.Now().Format("02/01/2006 15:04")))
	pdf.Ln(6)
	pdf.Cell(190, 6, "Sistema de Gestion de Lubricentros")

	// Output to buffer
	var buf bytes.Buffer
	err := pdf.Output(&buf)
	if err != nil {
		return nil, fmt.Errorf("generate PDF: %w", err)
	}
	return buf.Bytes(), nil
}

// GenerateServiceInvoice generates a PDF invoice for a service record.
func (g *VehicleReportGenerator) GenerateServiceInvoice(
	service *entity.ServiceRecord,
	vehicle *entity.Vehicle,
	parts []entity.ServicePartUsed,
) ([]byte, error) {

	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.AddPage()

	// Header
	pdf.SetFont("Arial", "B", 16)
	pdf.Cell(190, 10, "Factura de Servicio")
	pdf.Ln(12)

	// Date and Invoice Number
	pdf.SetFont("Arial", "", 10)
	pdf.Cell(140, 6, fmt.Sprintf("Fecha: %s", service.Fecha.Format("02/01/2006")))
	pdf.Cell(50, 6, fmt.Sprintf("Nro: SVC-%05d", service.ID))
	pdf.Ln(10)

	// Vehicle Info
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 8, "Datos del Vehiculo")
	pdf.Ln(6)

	pdf.SetFont("Arial", "", 10)
	pdf.Cell(40, 6, "Patente:")
	pdf.Cell(60, 6, vehicle.Patente)
	pdf.Ln(6)

	pdf.Cell(40, 6, "Vehiculo:")
	pdf.Cell(60, 6, fmt.Sprintf("%s %s", vehicle.Marca, vehicle.Modelo))
	pdf.Ln(6)

	pdf.Cell(40, 6, "Kilometraje:")
	pdf.Cell(60, 6, fmt.Sprintf("%d km", service.Km))
	pdf.Ln(10)

	// Service Details
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 8, "Detalle del Servicio")
	pdf.Ln(6)

	pdf.SetFont("Arial", "", 10)
	pdf.Cell(40, 6, "Tipo de Aceite:")
	pdf.Cell(60, 6, string(service.TipoAceite))
	pdf.Ln(6)

	pdf.Cell(40, 6, "Marca Aceite:")
	pdf.Cell(60, 6, service.MarcaAceite)
	pdf.Ln(10)

	// Parts if any
	if len(parts) > 0 {
		pdf.SetFont("Arial", "B", 12)
		pdf.Cell(190, 8, "Repuestos Utilizados")
		pdf.Ln(6)

		pdf.SetFont("Arial", "B", 8)
		pdf.Cell(80, 7, "Producto")
		pdf.Cell(30, 7, "Cantidad")
		pdf.Cell(40, 7, "Costo Unitario")
		pdf.Cell(40, 7, "Subtotal")
		pdf.Ln(7)

		pdf.SetFont("Arial", "", 8)
		for _, part := range parts {
			subtotal := part.CostoUnitario * float64(part.Cantidad)
			pdf.Cell(80, 6, fmt.Sprintf("Producto %d", part.ProductID))
			pdf.Cell(30, 6, fmt.Sprintf("%d", part.Cantidad))
			pdf.Cell(40, 6, fmt.Sprintf("$%.2f", part.CostoUnitario))
			pdf.Cell(40, 6, fmt.Sprintf("$%.2f", subtotal))
			pdf.Ln(6)
		}
	}

	// Observations
	if service.Observaciones != "" {
		pdf.Ln(6)
		pdf.SetFont("Arial", "B", 10)
		pdf.Cell(40, 6, "Observaciones:")
		pdf.Ln(6)
		pdf.SetFont("Arial", "", 9)
		pdf.MultiCell(180, 5, service.Observaciones, "", "", false)
	}

	// Total
	pdf.Ln(15)
	pdf.SetFont("Arial", "B", 14)
	pdf.Cell(140, 8, "Total:")
	if service.CostoTotal != nil {
		pdf.Cell(50, 8, fmt.Sprintf("$%.2f", *service.CostoTotal))
	} else {
		pdf.Cell(50, 8, "$0.00")
	}
	pdf.Ln(20)

	// Footer
	pdf.SetFont("Arial", "I", 8)
	pdf.Cell(190, 6, "Gracias por confiar en nosotros!")
	pdf.Ln(6)
	pdf.Cell(190, 6, "Sistema de Gestion de Lubricentros")

	// Output to buffer
	var buf bytes.Buffer
	err := pdf.Output(&buf)
	if err != nil {
		return nil, fmt.Errorf("generate PDF: %w", err)
	}
	return buf.Bytes(), nil
}

// GenerateRevenueReport generates a PDF revenue report.
func (g *VehicleReportGenerator) GenerateRevenueReport(
	startDate, endDate time.Time,
	services []entity.ServiceRecord,
	totalRevenue float64,
) ([]byte, error) {

	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.AddPage()

	// Title
	pdf.SetFont("Arial", "B", 16)
	pdf.Cell(190, 10, "Reporte de Ingresos")
	pdf.Ln(12)

	// Date Range
	pdf.SetFont("Arial", "", 10)
	pdf.Cell(40, 6, "Periodo:")
	pdf.Cell(60, 6, fmt.Sprintf("%s - %s", startDate.Format("02/01/2006"), endDate.Format("02/01/2006")))
	pdf.Ln(15)

	// Summary
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 8, "Resumen")
	pdf.Ln(6)

	pdf.SetFont("Arial", "", 10)
	pdf.Cell(40, 6, "Total de Servicios:")
	pdf.Cell(60, 6, fmt.Sprintf("%d", len(services)))
	pdf.Ln(6)

	pdf.Cell(40, 6, "Ingresos Totales:")
	pdf.Cell(60, 6, fmt.Sprintf("$%.2f", totalRevenue))
	pdf.Ln(6)

	if len(services) > 0 {
		avgTicket := totalRevenue / float64(len(services))
		pdf.Cell(40, 6, "Ticket Promedio:")
		pdf.Cell(60, 6, fmt.Sprintf("$%.2f", avgTicket))
	}
	pdf.Ln(15)

	// Services by Type
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(190, 8, "Servicios por Tipo de Aceite")
	pdf.Ln(6)

	pdf.SetFont("Arial", "B", 8)
	pdf.Cell(60, 7, "Tipo de Aceite")
	pdf.Cell(40, 7, "Cantidad")
	pdf.Cell(45, 7, "Porcentaje")
	pdf.Cell(45, 7, "Ingresos")
	pdf.Ln(7)

	pdf.SetFont("Arial", "", 8)
	typeStats := make(map[string]int)
	typeRevenue := make(map[string]float64)
	for _, svc := range services {
		typ := string(svc.TipoAceite)
		typeStats[typ]++
		if svc.CostoTotal != nil {
			typeRevenue[typ] += *svc.CostoTotal
		}
	}

	for typ, count := range typeStats {
		percentage := float64(count) / float64(len(services)) * 100
		pdf.Cell(60, 6, typ)
		pdf.Cell(40, 6, fmt.Sprintf("%d", count))
		pdf.Cell(45, 6, fmt.Sprintf("%.1f%%", percentage))
		pdf.Cell(45, 6, fmt.Sprintf("$%.2f", typeRevenue[typ]))
		pdf.Ln(6)
	}

	// Footer
	pdf.Ln(15)
	pdf.SetFont("Arial", "I", 8)
	pdf.Cell(190, 6, fmt.Sprintf("Reporte generado el %s", time.Now().Format("02/01/2006 15:04")))

	// Output to buffer
	var buf bytes.Buffer
	err := pdf.Output(&buf)
	if err != nil {
		return nil, fmt.Errorf("generate PDF: %w", err)
	}
	return buf.Bytes(), nil
}
