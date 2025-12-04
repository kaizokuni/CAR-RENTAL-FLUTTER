package middleware

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

func TenantMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		host := c.Request.Host
		// Remove port if present
		if strings.Contains(host, ":") {
			host = strings.Split(host, ":")[0]
		}

		parts := strings.Split(host, ".")
		var subdomain string

		// Handle localhost case (e.g., tenant.localhost)
		if len(parts) >= 2 && parts[len(parts)-1] == "localhost" {
			subdomain = parts[0]
		} else if len(parts) >= 3 {
			// Handle production case (e.g., tenant.domain.com)
			subdomain = parts[0]
		} else {
			// No subdomain found, use default for local development
			subdomain = "default"
		}

		// Skip if subdomain is 'www'
		if subdomain == "www" {
			subdomain = "default"
		}

		var tenant models.Tenant
		err := database.DB.QueryRow(context.Background(), "SELECT id, name, subdomain, db_name, subscription_tier FROM tenants WHERE subdomain = $1", subdomain).Scan(&tenant.ID, &tenant.Name, &tenant.Subdomain, &tenant.DBName, &tenant.SubscriptionTier)

		if err != nil {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
			return
		}

		// Store tenant in context
		c.Set("tenant", &tenant)
		c.Next()
	}
}

// TenantContextMiddleware resolves the tenant from the JWT claims (token_tenant_id)
// This is used for authenticated routes where the tenant is already known from the token
func TenantContextMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		tenantID, exists := c.Get("token_tenant_id")
		if !exists {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Tenant ID not found in token"})
			return
		}

		var tenant models.Tenant
		err := database.DB.QueryRow(context.Background(), "SELECT id, name, subdomain, db_name, subscription_tier FROM tenants WHERE id = $1", tenantID).Scan(&tenant.ID, &tenant.Name, &tenant.Subdomain, &tenant.DBName, &tenant.SubscriptionTier)

		if err != nil {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
			return
		}

		// Store tenant in context
		c.Set("tenant", &tenant)
		c.Next()
	}
}
