package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func TestRateLimiter(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("allows requests within limit", func(t *testing.T) {
		limiter := NewRateLimiter(5) // 5 requests per minute
		router := gin.New()
		router.Use(limiter.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(200, gin.H{"status": "ok"})
		})

		// Make 5 requests - all should succeed
		for i := 0; i < 5; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.1:1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if w.Code != http.StatusOK {
				t.Errorf("Request %d: expected status 200, got %d", i+1, w.Code)
			}
		}
	})

	t.Run("blocks requests exceeding limit", func(t *testing.T) {
		limiter := NewRateLimiter(3) // 3 requests per minute
		router := gin.New()
		router.Use(limiter.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(200, gin.H{"status": "ok"})
		})

		// Make 3 requests - should succeed
		for i := 0; i < 3; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.2:1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if w.Code != http.StatusOK {
				t.Errorf("Request %d: expected status 200, got %d", i+1, w.Code)
			}
		}

		// 4th request should be rate limited
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.2:1234"
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		if w.Code != http.StatusTooManyRequests {
			t.Errorf("Expected status 429, got %d", w.Code)
		}
	})

	t.Run("different IPs have separate limits", func(t *testing.T) {
		limiter := NewRateLimiter(2) // 2 requests per minute
		router := gin.New()
		router.Use(limiter.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(200, gin.H{"status": "ok"})
		})

		// IP 1: Make 2 requests
		for i := 0; i < 2; i++ {
			req := httptest.NewRequest("GET", "/test", nil)
			req.RemoteAddr = "192.168.1.3:1234"
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			if w.Code != http.StatusOK {
				t.Errorf("IP1 Request %d: expected status 200, got %d", i+1, w.Code)
			}
		}

		// IP 2: Should still be able to make requests
		req := httptest.NewRequest("GET", "/test", nil)
		req.RemoteAddr = "192.168.1.4:1234"
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Errorf("IP2 Request: expected status 200, got %d", w.Code)
		}
	})

	t.Run("rate limit resets over time", func(t *testing.T) {
		limiter := NewRateLimiter(60) // 60 requests per minute = 1 per second
		router := gin.New()
		router.Use(limiter.Middleware())
		router.GET("/test", func(c *gin.Context) {
			c.JSON(200, gin.H{"status": "ok"})
		})

		// Make first request
		req1 := httptest.NewRequest("GET", "/test", nil)
		req1.RemoteAddr = "192.168.1.5:1234"
		w1 := httptest.NewRecorder()
		router.ServeHTTP(w1, req1)

		if w1.Code != http.StatusOK {
			t.Errorf("First request: expected status 200, got %d", w1.Code)
		}

		// Wait for rate limit to reset (1 second)
		time.Sleep(1100 * time.Millisecond)

		// Make second request - should succeed
		req2 := httptest.NewRequest("GET", "/test", nil)
		req2.RemoteAddr = "192.168.1.5:1234"
		w2 := httptest.NewRecorder()
		router.ServeHTTP(w2, req2)

		if w2.Code != http.StatusOK {
			t.Errorf("Second request after wait: expected status 200, got %d", w2.Code)
		}
	})
}

func TestGetLimiter(t *testing.T) {
	limiter := NewRateLimiter(5)

	// Get limiter for IP1
	limiter1 := limiter.getLimiter("192.168.1.1")
	if limiter1 == nil {
		t.Error("Expected non-nil limiter for IP1")
	}

	// Get limiter for same IP - should return same instance
	limiter1Again := limiter.getLimiter("192.168.1.1")
	if limiter1 != limiter1Again {
		t.Error("Expected same limiter instance for same IP")
	}

	// Get limiter for different IP - should return different instance
	limiter2 := limiter.getLimiter("192.168.1.2")
	if limiter1 == limiter2 {
		t.Error("Expected different limiter instances for different IPs")
	}
}
