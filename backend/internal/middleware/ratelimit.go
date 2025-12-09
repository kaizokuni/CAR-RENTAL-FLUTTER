package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// Simple in-memory rate limiter
// In production, use Redis for distributed rate limiting

type IPRateLimiter struct {
	ips map[string]*rate.Limiter
	mu  sync.RWMutex
	r   rate.Limit
	b   int
}

func NewIPRateLimiter(r rate.Limit, b int) *IPRateLimiter {
	i := &IPRateLimiter{
		ips: make(map[string]*rate.Limiter),
		r:   r,
		b:   b,
	}

	// Cleanup routine to remove old entries (optional optimization)
	go func() {
		for {
			time.Sleep(10 * time.Minute)
			i.mu.Lock()
			// Reset map periodically to clear stale IPs
			// A better approach would be to track last access time
			i.ips = make(map[string]*rate.Limiter)
			i.mu.Unlock()
		}
	}()

	return i
}

func (i *IPRateLimiter) GetLimiter(ip string) *rate.Limiter {
	i.mu.Lock()
	defer i.mu.Unlock()

	limiter, exists := i.ips[ip]
	if !exists {
		limiter = rate.NewLimiter(i.r, i.b)
		i.ips[ip] = limiter
	}

	return limiter
}

func RateLimitMiddleware() gin.HandlerFunc {
	// Allow 50 requests per second with a burst of 100
	limiter := NewIPRateLimiter(50, 100)

	return func(c *gin.Context) {
		// Skip rate limiting for OPTIONS requests (CORS preflight)
		if c.Request.Method == "OPTIONS" {
			c.Next()
			return
		}

		ip := c.ClientIP()
		if !limiter.GetLimiter(ip).Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "Too many requests",
			})
			return
		}
		c.Next()
	}
}
