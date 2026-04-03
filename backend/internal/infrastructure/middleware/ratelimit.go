package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// RateLimiter implements a simple in-memory sliding window rate limiter.
type RateLimiter struct {
	clients map[string]*clientRecord
	mu      sync.Mutex
	limit   int
	window  time.Duration
}

type clientRecord struct {
	count    int
	lastSeen time.Time
}

// NewRateLimiter creates a rate limiter.
// limit = max requests per window duration.
func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		clients: make(map[string]*clientRecord),
		limit:   limit,
		window:  window,
	}

	// Cleanup expired entries periodically
	go rl.cleanup()

	return rl
}

// Middleware returns a Gin middleware that enforces rate limiting by IP.
func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()

		rl.mu.Lock()
		record, exists := rl.clients[ip]

		if !exists || time.Since(record.lastSeen) > rl.window {
			rl.clients[ip] = &clientRecord{count: 1, lastSeen: time.Now()}
			rl.mu.Unlock()
			c.Next()
			return
		}

		record.count++
		record.lastSeen = time.Now()

		if record.count > rl.limit {
			rl.mu.Unlock()
			c.Header("Retry-After", "60")
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error":   "Too Many Requests",
				"message": "Rate limit exceeded. Please try again later.",
			})
			return
		}

		rl.mu.Unlock()
		c.Next()
	}
}

// cleanup removes expired entries every minute.
func (rl *RateLimiter) cleanup() {
	ticker := time.NewTicker(time.Minute)
	for range ticker.C {
		rl.mu.Lock()
		for ip, record := range rl.clients {
			if time.Since(record.lastSeen) > rl.window {
				delete(rl.clients, ip)
			}
		}
		rl.mu.Unlock()
	}
}
