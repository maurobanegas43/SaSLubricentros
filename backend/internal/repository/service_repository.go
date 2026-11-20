package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/lubricentros/api/internal/domain/entity"
)

// ServiceRecordRepositoryImpl is the MariaDB implementation of ServiceRecordRepository.
type ServiceRecordRepositoryImpl struct {
	*BaseRepository
}

// NewServiceRecordRepository creates a new service record repository.
func NewServiceRecordRepository(db *sql.DB) *ServiceRecordRepositoryImpl {
	return &ServiceRecordRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new service record. Service records are immutable.
func (r *ServiceRecordRepositoryImpl) Create(ctx context.Context, record *entity.ServiceRecord) error {
	query := `INSERT INTO service_records (vehicle_id, appointment_id, fecha, km, tipo_aceite, marca_aceite,
		costo_total, observaciones, proximo_service_km, created_by, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	record.CreatedAt = now

	var id int64
	err := r.QueryRowContext(ctx, query,
		record.VehicleID, record.AppointmentID, record.Fecha, record.Km,
		record.TipoAceite, record.MarcaAceite, record.CostoTotal,
		record.Observaciones, record.ProximoServiceKm, record.CreatedBy, record.CreatedAt,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "service record create")
	}

	record.ID = uint(id)

	return nil
}

// GetByID retrieves a service record by its ID.
func (r *ServiceRecordRepositoryImpl) GetByID(ctx context.Context, id uint) (*entity.ServiceRecord, error) {
	query := `SELECT id, vehicle_id, appointment_id, fecha, km, tipo_aceite, marca_aceite,
		costo_total, observaciones, proximo_service_km, created_by, created_at
		FROM service_records WHERE id = ?`

	var s entity.ServiceRecord
	err := r.QueryRowContext(ctx, query, id).Scan(
		&s.ID, &s.VehicleID, &s.AppointmentID, &s.Fecha, &s.Km,
		&s.TipoAceite, &s.MarcaAceite, &s.CostoTotal,
		&s.Observaciones, &s.ProximoServiceKm, &s.CreatedBy, &s.CreatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "service record get by id")
	}

	return &s, nil
}

// GetByVehicleID retrieves service records for a vehicle with pagination.
func (r *ServiceRecordRepositoryImpl) GetByVehicleID(ctx context.Context, vehicleID uint, offset, limit int) ([]entity.ServiceRecord, error) {
	query := `SELECT id, vehicle_id, appointment_id, fecha, km, tipo_aceite, marca_aceite,
		costo_total, observaciones, proximo_service_km, created_by, created_at
		FROM service_records WHERE vehicle_id = ? ORDER BY fecha DESC LIMIT ? OFFSET ?`

	rows, err := r.QueryContext(ctx, query, vehicleID, limit, offset)
	if err != nil {
		return nil, WrapError(err, "service record get by vehicle id")
	}
	defer rows.Close()

	var records []entity.ServiceRecord
	for rows.Next() {
		var s entity.ServiceRecord
		var appointmentID sql.NullInt64
		var costoTotal sql.NullFloat64
		var proximoServiceKm sql.NullInt64
		if err := rows.Scan(
			&s.ID, &s.VehicleID, &appointmentID, &s.Fecha, &s.Km,
			&s.TipoAceite, &s.MarcaAceite, &costoTotal,
			&s.Observaciones, &proximoServiceKm, &s.CreatedBy, &s.CreatedAt,
		); err != nil {
			return nil, WrapError(err, "service record get by vehicle id: scan")
		}
		if appointmentID.Valid {
			aid := uint(appointmentID.Int64)
			s.AppointmentID = &aid
		}
		if costoTotal.Valid {
			ct := costoTotal.Float64
			s.CostoTotal = &ct
		}
		if proximoServiceKm.Valid {
			psk := uint(proximoServiceKm.Int64)
			s.ProximoServiceKm = &psk
		}
		records = append(records, s)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "service record get by vehicle id: iterate")
	}

	return records, nil
}

// GetLastByVehicleID retrieves the most recent service record for a vehicle.
func (r *ServiceRecordRepositoryImpl) GetLastByVehicleID(ctx context.Context, vehicleID uint) (*entity.ServiceRecord, error) {
	query := `SELECT id, vehicle_id, appointment_id, fecha, km, tipo_aceite, marca_aceite,
		costo_total, observaciones, proximo_service_km, created_by, created_at
		FROM service_records WHERE vehicle_id = ? ORDER BY fecha DESC LIMIT 1`

	var s entity.ServiceRecord
	var appointmentID sql.NullInt64
	var costoTotal sql.NullFloat64
	var proximoServiceKm sql.NullInt64
	err := r.QueryRowContext(ctx, query, vehicleID).Scan(
		&s.ID, &s.VehicleID, &appointmentID, &s.Fecha, &s.Km,
		&s.TipoAceite, &s.MarcaAceite, &costoTotal,
		&s.Observaciones, &proximoServiceKm, &s.CreatedBy, &s.CreatedAt,
	)
	if err != nil {
		return nil, WrapError(err, "service record get last by vehicle id")
	}

	if appointmentID.Valid {
		aid := uint(appointmentID.Int64)
		s.AppointmentID = &aid
	}
	if costoTotal.Valid {
		ct := costoTotal.Float64
		s.CostoTotal = &ct
	}
	if proximoServiceKm.Valid {
		psk := uint(proximoServiceKm.Int64)
		s.ProximoServiceKm = &psk
	}

	return &s, nil
}

// CountByVehicleID returns the total number of service records for a vehicle.
func (r *ServiceRecordRepositoryImpl) CountByVehicleID(ctx context.Context, vehicleID uint) (int64, error) {
	var count int64
	err := r.QueryRowContext(ctx, "SELECT COUNT(*) FROM service_records WHERE vehicle_id = ?", vehicleID).Scan(&count)
	if err != nil {
		return 0, WrapError(err, "service record count by vehicle id")
	}
	return count, nil
}

// ServiceAddendumRepositoryImpl is the MariaDB implementation of ServiceAddendumRepository.
type ServiceAddendumRepositoryImpl struct {
	*BaseRepository
}

// NewServiceAddendumRepository creates a new service addendum repository.
func NewServiceAddendumRepository(db *sql.DB) *ServiceAddendumRepositoryImpl {
	return &ServiceAddendumRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a new service addendum.
func (r *ServiceAddendumRepositoryImpl) Create(ctx context.Context, addendum *entity.ServiceAddendum) error {
	query := `INSERT INTO service_addendums (service_id, description, created_by, created_at)
		VALUES (?, ?, ?, ?)
		RETURNING id`

	now := time.Now()
	addendum.CreatedAt = now

	var id int64
	err := r.QueryRowContext(ctx, query,
		addendum.ServiceID, addendum.Reason, addendum.CreatedBy, addendum.CreatedAt,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "service addendum create")
	}

	addendum.ID = uint(id)

	return nil
}

// GetByServiceID retrieves all addenda for a service record.
func (r *ServiceAddendumRepositoryImpl) GetByServiceID(ctx context.Context, serviceID uint) ([]entity.ServiceAddendum, error) {
	query := `SELECT id, service_id, description, created_by, created_at
		FROM service_addendums WHERE service_id = ? ORDER BY created_at ASC`

	rows, err := r.QueryContext(ctx, query, serviceID)
	if err != nil {
		return nil, WrapError(err, "service addendum get by service id")
	}
	defer rows.Close()

	var addenda []entity.ServiceAddendum
	for rows.Next() {
		var a entity.ServiceAddendum
		if err := rows.Scan(
			&a.ID, &a.ServiceID, &a.Reason, &a.CreatedBy, &a.CreatedAt,
		); err != nil {
			return nil, WrapError(err, "service addendum get by service id: scan")
		}
		addenda = append(addenda, a)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "service addendum get by service id: iterate")
	}

	return addenda, nil
}

// ServicePartUsedRepositoryImpl is the MariaDB implementation of ServicePartUsedRepository.
type ServicePartUsedRepositoryImpl struct {
	*BaseRepository
}

// NewServicePartUsedRepository creates a new service parts repository.
func NewServicePartUsedRepository(db *sql.DB) *ServicePartUsedRepositoryImpl {
	return &ServicePartUsedRepositoryImpl{
		BaseRepository: NewBaseRepository(db),
	}
}

// Create inserts a single service part used record.
func (r *ServicePartUsedRepositoryImpl) Create(ctx context.Context, part *entity.ServicePartUsed) error {
	query := `INSERT INTO service_parts_used (service_id, product_id, cantidad, costo_unitario)
		VALUES (?, ?, ?, ?)
		RETURNING id`

	var id int64
	err := r.QueryRowContext(ctx, query,
		part.ServiceID, part.ProductID, part.Cantidad, part.CostoUnitario,
	).Scan(&id)
	if err != nil {
		return WrapError(err, "service part create")
	}

	part.ID = uint(id)

	return nil
}

// GetByServiceID retrieves all parts used in a service.
func (r *ServicePartUsedRepositoryImpl) GetByServiceID(ctx context.Context, serviceID uint) ([]entity.ServicePartUsed, error) {
	query := `SELECT id, service_id, product_id, cantidad, costo_unitario
		FROM service_parts_used WHERE service_id = ? ORDER BY id ASC`

	rows, err := r.QueryContext(ctx, query, serviceID)
	if err != nil {
		return nil, WrapError(err, "service part get by service id")
	}
	defer rows.Close()

	var parts []entity.ServicePartUsed
	for rows.Next() {
		var p entity.ServicePartUsed
		if err := rows.Scan(
			&p.ID, &p.ServiceID, &p.ProductID, &p.Cantidad, &p.CostoUnitario,
		); err != nil {
			return nil, WrapError(err, "service part get by service id: scan")
		}
		parts = append(parts, p)
	}

	if err := rows.Err(); err != nil {
		return nil, WrapError(err, "service part get by service id: iterate")
	}

	return parts, nil
}

// CreateBatch inserts multiple service parts in a single transaction.
func (r *ServicePartUsedRepositoryImpl) CreateBatch(ctx context.Context, parts []entity.ServicePartUsed) error {
	if len(parts) == 0 {
		return nil
	}

	query := `INSERT INTO service_parts_used (service_id, product_id, cantidad, costo_unitario)
		VALUES (?, ?, ?, ?)
		RETURNING id`

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return WrapError(err, "service part create batch: begin tx")
	}
	defer func() { _ = tx.Rollback() }()

	stmt, err := tx.PrepareContext(ctx, rebindPostgres(query))
	if err != nil {
		return WrapError(err, "service part create batch: prepare")
	}
	defer stmt.Close()

	for i := range parts {
		var id int64
		err := stmt.QueryRowContext(ctx,
			parts[i].ServiceID, parts[i].ProductID, parts[i].Cantidad, parts[i].CostoUnitario,
		).Scan(&id)
		if err != nil {
			return WrapError(err, "service part create batch: exec")
		}
		parts[i].ID = uint(id)
	}

	if err := tx.Commit(); err != nil {
		return WrapError(err, "service part create batch: commit")
	}

	return nil
}
