package audit

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"encoding/json"

	"github.com/gin-gonic/gin"
)

// LogAudit records an action in the audit_logs table
func LogAudit(c *gin.Context, action string, details interface{}) {
	// Get Tenant DB
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		// Can't log if we don't know the tenant DB
		return
	}
	tenant := tenantCtx.(models.Tenant)
	db, err := database.GetTenantDB(tenant.DBName)
	if err != nil {
		return
	}

	// Get User ID
	userIDCtx, exists := c.Get("user_id")
	var userID interface{} = nil
	if exists {
		userID = userIDCtx.(string)
	}

	// Get IP
	ip := c.ClientIP()

	// Serialize details
	detailsJSON, _ := json.Marshal(details)

	// Insert into DB
	// We run this in a goroutine to not block the request,
	// but we need a new context since the request context might be cancelled
	go func() {
		_, _ = db.Exec(context.Background(),
			`INSERT INTO audit_logs (tenant_id, user_id, action, details, ip_address) 
			 VALUES ($1, $2, $3, $4, $5)`,
			tenant.ID, userID, action, detailsJSON, ip)
	}()
}
