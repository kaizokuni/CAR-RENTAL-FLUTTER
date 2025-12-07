package handlers

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Notification struct {
	ID        string    `json:"id"`
	Title     string    `json:"title"`
	Message   string    `json:"message"`
	Type      string    `json:"type"`
	IsRead    bool      `json:"is_read"`
	CreatedAt time.Time `json:"created_at"`
}

// Helper to get tenant DB connection (reused logic)
func getTenantDBForNotifications(c *gin.Context) (*pgxpool.Pool, *models.Tenant, string, error) {
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		return nil, nil, "", context.Canceled
	}
	tenant := tenantCtx.(*models.Tenant)

	userIDCtx, exists := c.Get("user_id")
	var userID string
	if exists {
		userID = userIDCtx.(string)
	}

	db, err := database.GetTenantDB(tenant.DBName)
	return db, tenant, userID, err
}

func GetNotifications(c *gin.Context) {
	db, _, userID, err := getTenantDBForNotifications(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	// Fetch notifications for the specific user OR system-wide (user_id IS NULL)
	// In a real multi-tenant app, we might filter by tenant_id in the query if the DB is shared,
	// but here we are connected to the tenant's specific DB, so we just filter by user.
	// However, our schema has tenant_id, so let's respect it if we were on a shared DB.
	// Since we are on a dedicated DB, we just check user_id.

	query := `
		SELECT id, title, message, type, is_read, created_at 
		FROM notifications 
		WHERE user_id = $1 OR user_id IS NULL 
		ORDER BY created_at DESC 
		LIMIT 50
	`

	rows, err := db.Query(context.Background(), query, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notifications: " + err.Error()})
		return
	}
	defer rows.Close()

	var notifications []Notification
	for rows.Next() {
		var n Notification
		if err := rows.Scan(&n.ID, &n.Title, &n.Message, &n.Type, &n.IsRead, &n.CreatedAt); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan notification: " + err.Error()})
			return
		}
		notifications = append(notifications, n)
	}

	if notifications == nil {
		notifications = []Notification{}
	}

	c.JSON(http.StatusOK, notifications)
}

func MarkNotificationRead(c *gin.Context) {
	id := c.Param("id")
	db, _, _, err := getTenantDBForNotifications(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	_, err = db.Exec(context.Background(), "UPDATE notifications SET is_read = TRUE WHERE id = $1", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark notification as read: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Notification marked as read"})
}

// Internal helper to create a notification
// This isn't an API endpoint but a function other handlers can call
func CreateNotificationInternal(db *pgxpool.Pool, tenantID, userID, title, message, notifType string) error {
	// If userID is empty, pass nil to SQL
	var userIDArg interface{} = userID
	if userID == "" {
		userIDArg = nil
	}

	_, err := db.Exec(context.Background(),
		"INSERT INTO notifications (tenant_id, user_id, title, message, type) VALUES ($1, $2, $3, $4, $5)",
		tenantID, userIDArg, title, message, notifType)
	return err
}
