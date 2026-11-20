package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

// Client for Supabase Storage
type Client struct {
	storageURL string
	serviceKey string
	bucketName string
	httpClient *http.Client
}

// NewClient creates a new Supabase Storage client
// storageURL: e.g., https://<project-ref>.supabase.co/storage/v1
// serviceKey: SUPABASE_SERVICE_ROLE_KEY (not anon key)
func NewClient(storageURL, serviceKey, bucketName string) *Client {
	return &Client{
		storageURL: storageURL,
		serviceKey: serviceKey,
		bucketName: bucketName,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// UploadFile uploads a file to Supabase Storage
func (c *Client) UploadFile(ctx context.Context, path string, file *multipart.FileHeader) (string, error) {
	src, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer src.Close()

	fileContent, err := io.ReadAll(src)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	return c.uploadFileBytes(ctx, path, fileContent, file.Header.Get("Content-Type"))
}

// UploadFileFromDisk uploads a file from disk to Supabase Storage
func (c *Client) UploadFileFromDisk(ctx context.Context, path, filePath string) error {
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file from disk: %w", err)
	}

	ext := filepath.Ext(filePath)
	contentType := getContentType(ext)

	_, err = c.uploadFileBytes(ctx, path, fileContent, contentType)
	return err
}

// uploadFileBytes uploads raw file bytes to Supabase Storage
func (c *Client) uploadFileBytes(ctx context.Context, path string, fileContent []byte, contentType string) (string, error) {
	url := fmt.Sprintf("%s/object/%s/%s", c.storageURL, c.bucketName, path)

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(fileContent))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.serviceKey))
	req.Header.Set("Content-Type", contentType)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to upload file: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("upload failed with status %d: %s", resp.StatusCode, string(body))
	}

	publicURL := fmt.Sprintf("%s/object/public/%s/%s", c.storageURL, c.bucketName, path)
	return publicURL, nil
}

// DeleteFile deletes a file from Supabase Storage
func (c *Client) DeleteFile(ctx context.Context, path string) error {
	url := fmt.Sprintf("%s/object/%s/%s", c.storageURL, c.bucketName, path)

	req, err := http.NewRequestWithContext(ctx, "DELETE", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.serviceKey))

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to delete file: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("delete failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}

// GetPublicURL returns the public URL for a file
func (c *Client) GetPublicURL(path string) string {
	return fmt.Sprintf("%s/object/public/%s/%s", c.storageURL, c.bucketName, path)
}

// getContentType returns the content type for a file extension
func getContentType(ext string) string {
	contentTypes := map[string]string{
		".jpg":  "image/jpeg",
		".jpeg": "image/jpeg",
		".png":  "image/png",
		".gif":  "image/gif",
		".webp": "image/webp",
		".pdf":  "application/pdf",
	}

	if ct, ok := contentTypes[ext]; ok {
		return ct
	}
	return "application/octet-stream"
}
