package database

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// Config holds the database connection parameters.
type Config struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
}

// NewConfig reads connection parameters from environment variables.
func NewConfig() Config {
	return Config{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     getEnv("DB_PORT", "3306"),
		User:     getEnv("DB_USER", "root"),
		Password: getEnv("DB_PASSWORD", ""),
		Name:     getEnv("DB_NAME", "lubricentros"),
	}
}

// Connect opens a MariaDB connection pool using the go-sql-driver/mysql driver.
// It configures connection pool settings and performs an initial health check (Ping).
func Connect(cfg Config) (*sql.DB, error) {
	// MariaDB DSN format: user:password@tcp(host:port)/dbname?parseTime=true&charset=utf8mb4
	dsn := fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s?parseTime=true&charset=utf8mb4&collation=utf8mb4_unicode_ci",
		cfg.User,
		cfg.Password,
		cfg.Host,
		cfg.Port,
		cfg.Name,
	)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Connection pool settings — tuned for a small/medium SaaS application.
	db.SetMaxOpenConns(25)                 // Maximum simultaneous open connections
	db.SetMaxIdleConns(5)                  // Connections kept alive when idle
	db.SetConnMaxLifetime(5 * time.Minute) // Max time a connection can be reused

	// Health check — verify the database is reachable.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return db, nil
}

// HealthCheck performs a quick ping to verify the database is alive.
func HealthCheck(db *sql.DB) error {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	return db.PingContext(ctx)
}

// getEnv returns the value of an environment variable or a default fallback.
func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
