package config

import (
	"os"
)

// StorageConfig holds Supabase Storage configuration.
type StorageConfig struct {
	StorageURL string
	ServiceKey string
	BucketName string
}

// LoadStorageConfig loads Supabase Storage configuration from environment variables.
func LoadStorageConfig() *StorageConfig {
	return &StorageConfig{
		StorageURL: os.Getenv("SUPABASE_STORAGE_URL"),
		ServiceKey: os.Getenv("SUPABASE_SERVICE_ROLE_KEY"),
		BucketName: os.Getenv("SUPABASE_STORAGE_BUCKET"),
	}
}

// IsValid returns true if all required storage configuration is present.
func (c *StorageConfig) IsValid() bool {
	return c.StorageURL != "" && c.ServiceKey != "" && c.BucketName != ""
}
