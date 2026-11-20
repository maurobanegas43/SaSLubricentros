package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
	"github.com/lubricentros/api/internal/database"
)

// Config holds all application configuration loaded from environment variables.
type Config struct {
	// Server
	Port        string
	Environment string // "development" or "production"

	// Database
	Database database.Config

	// JWT
	JWTSecret     string
	JWTExpiration time.Duration

	// Refresh Token
	RefreshTokenExpiration time.Duration
}

// Load reads configuration from .env file (if present) and environment variables.
// It validates that all required fields are set.
func Load() (*Config, error) {
	// Load .env file if it exists (non-fatal if missing)
	_ = godotenv.Load()

	cfg := &Config{
		Port:        getEnv("PORT", "8080"),
		Environment: getEnv("APP_ENV", "development"),
		Database:    database.NewConfig(),
		JWTSecret:   os.Getenv("JWT_SECRET"),
	}

	// Parse JWT expiration (default: 15 minutes)
	jwtExp := getEnv("JWT_EXPIRATION_MINUTES", "15")
	if minutes, err := strconv.Atoi(jwtExp); err == nil {
		cfg.JWTExpiration = time.Duration(minutes) * time.Minute
	} else {
		cfg.JWTExpiration = 15 * time.Minute
	}

	// Parse refresh token expiration (default: 7 days)
	rtExp := getEnv("REFRESH_TOKEN_EXPIRATION_HOURS", "168")
	if hours, err := strconv.Atoi(rtExp); err == nil {
		cfg.RefreshTokenExpiration = time.Duration(hours) * time.Hour
	} else {
		cfg.RefreshTokenExpiration = 7 * 24 * time.Hour
	}

	// Validate required fields
	if err := cfg.validate(); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	return cfg, nil
}

// validate checks that all required configuration fields are present.
func (c *Config) validate() error {
	if c.JWTSecret == "" {
		return fmt.Errorf("JWT_SECRET is required")
	}
	if len(c.JWTSecret) < 32 {
		return fmt.Errorf("JWT_SECRET must be at least 32 characters long")
	}
	if c.Database.Host == "" {
		return fmt.Errorf("DB_HOST is required")
	}
	if c.Database.Name == "" {
		return fmt.Errorf("DB_NAME is required")
	}
	return nil
}

// getEnv returns the value of an environment variable or a default fallback.
func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
