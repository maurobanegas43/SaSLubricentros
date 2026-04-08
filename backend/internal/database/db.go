package database

import (
	"context"
	"database/sql"
	"fmt"
	"net"
	"os"
	"time"

	_ "github.com/lib/pq"
)

// Config holds the database connection parameters.
type Config struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSLMode  string
}

// NewConfig reads connection parameters from environment variables.
func NewConfig() Config {
	return Config{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     getEnv("DB_PORT", "5432"),
		User:     getEnv("DB_USER", "postgres"),
		Password: getEnv("DB_PASSWORD", ""),
		Name:     getEnv("DB_NAME", "postgres"),
		SSLMode:  getEnv("DB_SSLMODE", "require"),
	}
}

// Connect opens a PostgreSQL connection pool with IPv4 enforcement and retry logic.
// It configures connection pool settings and performs an initial health check.
func Connect(cfg Config) (*sql.DB, error) {
	// Custom resolver that forces IPv4
	resolver := &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			d := net.Dialer{
				Timeout: 5 * time.Second,
			}
			// Force IPv4 by using 4to6 mapping or direct IPv4
			return d.DialContext(ctx, "tcp4", address)
		},
	}

	// Get IPv4 address for the host
	ipv4Host, err := resolveIPv4(cfg.Host, resolver)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve hostname %s to IPv4: %w", cfg.Host, err)
	}

	fmt.Printf("[DB] Using IPv4 address: %s (resolved from %s)\n", ipv4Host, cfg.Host)

	// PostgreSQL DSN format with IPv4 address
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		ipv4Host,
		cfg.Port,
		cfg.User,
		cfg.Password,
		cfg.Name,
		cfg.SSLMode,
	)

	// Retry logic with exponential backoff for connection
	maxRetries := 3
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		db, err := sql.Open("postgres", dsn)
		if err != nil {
			lastErr = fmt.Errorf("failed to open database connection (attempt %d/%d): %w", attempt, maxRetries, err)
			time.Sleep(time.Duration(attempt) * time.Second)
			continue
		}

		// Connection pool settings
		db.SetMaxOpenConns(25)
		db.SetMaxIdleConns(5)
		db.SetConnMaxLifetime(5 * time.Minute)
		db.SetConnMaxIdleTime(1 * time.Minute)

		// Health check
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := db.PingContext(ctx); err != nil {
			db.Close()
			lastErr = fmt.Errorf("failed to ping database (attempt %d/%d): %w", attempt, maxRetries, err)
			time.Sleep(time.Duration(attempt*2) * time.Second)
			continue
		}

		fmt.Println("[DB] Successfully connected to PostgreSQL")
		return db, nil
	}

	return nil, fmt.Errorf("failed to connect after %d attempts: %w", maxRetries, lastErr)
}

// resolveIPv4 resolves a hostname to an IPv4 address.
// It falls back to the original hostname if no IPv4 is found.
func resolveIPv4(host string, resolver *net.Resolver) (string, error) {
	// If it's already an IP address, return as-is
	if net.ParseIP(host) != nil {
		return host, nil
	}

	// Try to resolve to IPv4
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	addrs, err := resolver.LookupIP(ctx, "ip4", host)
	if err != nil {
		// Fallback: try using system resolver
		return fallbackResolveIPv4(host)
	}

	// Find first IPv4 address
	for _, addr := range addrs {
		if v4 := addr.To4(); v4 != nil {
			return v4.String(), nil
		}
	}

	// No IPv4 found, fallback
	return fallbackResolveIPv4(host)
}

// fallbackResolveIPv4 uses the standard library to resolve to IPv4
func fallbackResolveIPv4(host string) (string, error) {
	// Use net.LookupIP which tries both IPv4 and IPv6
	addrs, err := net.LookupIP(host)
	if err != nil {
		return host, fmt.Errorf("hostname resolution failed: %w", err)
	}

	// Filter for IPv4
	for _, addr := range addrs {
		if v4 := addr.To4(); v4 != nil {
			return v4.String(), nil
		}
	}

	// If no IPv4, try to parse A record manually via DNS
	// Fallback to original host and let the driver try
	fmt.Printf("[DB] Warning: No IPv4 address found for %s, using original hostname\n", host)
	return host, nil
}

// ConnectWithURL connects using a DATABASE_URL environment variable.
// This is an alternative connection method for Supabase/Heroku style URLs.
func ConnectWithURL() (*sql.DB, error) {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL environment variable is not set")
	}

	// Parse the URL to extract host and force IPv4
	host, err := extractHostFromURL(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database URL: %w", err)
	}

	// Resolve to IPv4
	ipv4Host, err := resolveIPv4(host, &net.Resolver{
		PreferGo: true,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to resolve IPv4: %w", err)
	}

	// Replace host in URL with IPv4
	dsn := replaceHostInURL(databaseURL, ipv4Host)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return db, nil
}

// extractHostFromURL extracts the host from a PostgreSQL connection URL
func extractHostFromURL(url string) (string, error) {
	// URL format: postgres://user:pass@host:port/db?params
	hostPort := ""

	// Simple parsing - find the @ symbol and take everything after it until : or /
	if idx := 1; idx < len(url) && idx >= 0 {
		// Try to find @ in the URL
		for i, c := range url {
			if c == '@' {
				hostPort = url[i+1:]
				break
			}
		}
	}

	if hostPort == "" {
		return "", fmt.Errorf("invalid URL format: no @ found")
	}

	// Remove port if present
	for i := 0; i < len(hostPort); i++ {
		if hostPort[i] == ':' {
			return hostPort[:i], nil
		}
		if hostPort[i] == '?' || hostPort[i] == '/' {
			return hostPort[:i], nil
		}
	}

	return hostPort, nil
}

// replaceHostInURL replaces the hostname in the URL with a new one
func replaceHostInURL(url, newHost string) string {
	// Find where host starts (after @)
	atIdx := -1
	for i, c := range url {
		if c == '@' {
			atIdx = i
			break
		}
	}

	if atIdx == -1 {
		return url
	}

	// Find where host ends (at : or ? or /)
	start := atIdx + 1
	end := len(url)
	for i := start; i < len(url); i++ {
		if url[i] == ':' || url[i] == '?' || url[i] == '/' {
			end = i
			break
		}
	}

	// Rebuild URL with new host
	return url[:start] + newHost + url[end:]
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
