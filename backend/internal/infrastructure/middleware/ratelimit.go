package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// RateLimiter implements token bucket rate limiting per IP address
type RateLimiter struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	rate     rate.Limit
	burst    int
}

// NewRateLimiter creates a new rate limiter
// rate: requests per second (e.g., 5/60 = 0.0833 for 5 requests per minute)
// burst: maximum burst size (e.g., 5 for 5 requests)
func NewRateLimiter(requestsPerMinute int) *RateLimiter {
	r := float64(requestsPerMinute) / 60.0 // Convert to requests per second
	return &RateLimiter{
		limiters: make(map[string]*rate.Limiter),
		rate:     rate.Limit(r),
		burst:    requestsPerMinute,
	}
}

// getLimiter returns the rate limiter for a given IP address
func (rl *RateLimiter) getLimiter(ip string) *rate.Limiter {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	limiter, exists := rl.limiters[ip]
	if !exists {
		limiter = rate.NewLimiter(rl.rate, rl.burst)
		rl.limiters[ip] = limiter
	}

	return limiter
}

// Middleware returns a Gin middleware function for rate limiting
func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	// Start cleanup goroutine
	go rl.cleanupStaleEntries()

	return func(c *gin.Context) {
		ip := c.ClientIP()
		limiter := rl.getLimiter(ip)

		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": gin.H{
					"code":    "rate_limited",
					"message": "Too many requests. Please try again later.",
					"retry_after": 60,
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// cleanupStaleEntries removes limiters that haven't been used recently
func (rl *RateLimiter) cleanupStaleEntries() {
	ticker := time.NewTicker(10 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()
		// In a production system, you'd track last access time
		// For simplicity, we'll just clear all entries periodically
		// This is acceptable since rate limiters are recreated on demand
		if len(rl.limiters) > 1000 {
			rl.limiters = make(map[string]*rate.Limiter)
		}
		rl.mu.Unlock()
	}
}

// RateLimit creates a rate limiting middleware with the specified requests per minute
func RateLimit(requestsPerMinute int) gin.HandlerFunc {
	limiter := NewRateLimiter(requestsPerMinute)
	return limiter.Middleware()
}
