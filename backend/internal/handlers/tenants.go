package handlers

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"fmt"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type CreateTenantRequest struct {
	Name          string                `form:"name" binding:"required"`
	Subdomain     string                `form:"subdomain" binding:"required"`
	AdminEmail    string                `form:"admin_email" binding:"required,email"`
	AdminPassword string                `form:"admin_password" binding:"required,min=6"`
	Tier          string                `form:"tier" binding:"required,oneof=normal pro premium"`
	PaymentMethod string                `form:"payment_method" binding:"required"`
	Logo          *multipart.FileHeader `form:"logo"`
}

func CreateTenant(c *gin.Context) {
	var req CreateTenantRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Handle Logo Upload
	var logoURL string
	if req.Logo != nil {
		// Ensure uploads directory exists
		uploadDir := "uploads/tenants"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
			return
		}

		// Generate unique filename
		filename := fmt.Sprintf("%d_%s", time.Now().Unix(), req.Logo.Filename)
		filepath := filepath.Join(uploadDir, filename)

		if err := c.SaveUploadedFile(req.Logo, filepath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save logo"})
			return
		}
		logoURL = "/" + filepath
	}

	dbName := fmt.Sprintf("tenant_%s", req.Subdomain)

	// 1. Create Tenant Record in Master DB
	var tenantID string
	err := database.DB.QueryRow(context.Background(),
		"INSERT INTO tenants (name, subdomain, db_name, subscription_tier, payment_method, logo_url) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id",
		req.Name, req.Subdomain, dbName, req.Tier, req.PaymentMethod, logoURL).Scan(&tenantID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create tenant record: " + err.Error()})
		return
	}

	// 2. Create Tenant Database
	err = database.CreateTenantDB(dbName)
	if err != nil {
		// Rollback tenant creation (simplified)
		database.DB.Exec(context.Background(), "DELETE FROM tenants WHERE id = $1", tenantID)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to provision database: " + err.Error()})
		return
	}

	// 3. Migrate Tenant Database
	err = database.MigrateTenantDB(dbName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to migrate tenant database: " + err.Error()})
		return
	}

	// 4. Create Admin User in Tenant DB
	pool, err := database.GetTenantDB(dbName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to new tenant DB: " + err.Error()})
		return
	}

	// Insert Tenant Record into Tenant DB (to satisfy FK)
	_, err = pool.Exec(context.Background(), "INSERT INTO tenants (id, name, subdomain, db_name, subscription_tier, logo_url) VALUES ($1, $2, $3, $4, $5, $6)", tenantID, req.Name, req.Subdomain, dbName, req.Tier, logoURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to insert tenant record into tenant DB: " + err.Error()})
		return
	}

	// Create Admin Role
	var roleID string
	err = pool.QueryRow(context.Background(), "INSERT INTO roles (name, description) VALUES ('admin', 'Administrator') RETURNING id").Scan(&roleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create admin role: " + err.Error()})
		return
	}

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.AdminPassword), bcrypt.DefaultCost)
	_, err = pool.Exec(context.Background(),
		"INSERT INTO users (tenant_id, email, password_hash, first_name, last_name, role_id) VALUES ($1, $2, $3, 'Admin', 'User', $4)",
		tenantID, req.AdminEmail, string(hashedPassword), roleID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create admin user: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Tenant provisioned successfully", "tenant_id": tenantID})
}

func GetTenant(c *gin.Context) {
	id := c.Param("id")
	var tenant models.Tenant
	err := database.DB.QueryRow(context.Background(), "SELECT id, name, subdomain, db_name FROM tenants WHERE id = $1", id).Scan(&tenant.ID, &tenant.Name, &tenant.Subdomain, &tenant.DBName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
		return
	}
	c.JSON(http.StatusOK, tenant)
}

func DeleteTenant(c *gin.Context) {
	id := c.Param("id")

	// Get DB Name first
	var dbName string
	err := database.DB.QueryRow(context.Background(), "SELECT db_name FROM tenants WHERE id = $1", id).Scan(&dbName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
		return
	}

	// Delete from Master DB
	_, err = database.DB.Exec(context.Background(), "DELETE FROM tenants WHERE id = $1", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete tenant record"})
		return
	}

	// Drop Database (Optional - maybe keep for backup?)
	// For now, let's keep it but maybe rename it or just log it.
	// Dropping DB requires closing all connections to it first.

	c.JSON(http.StatusOK, gin.H{"message": "Tenant deleted successfully"})
}

func GetAllTenants(c *gin.Context) {
	var tenants []models.Tenant
	// Exclude the "admin" tenant from the list - it's for platform management only, not a real shop
	rows, err := database.DB.Query(context.Background(), "SELECT id, name, subdomain, db_name, created_at FROM tenants WHERE subdomain != 'admin' ORDER BY created_at DESC")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tenants"})
		return
	}
	defer rows.Close()

	for rows.Next() {
		var tenant models.Tenant
		err := rows.Scan(&tenant.ID, &tenant.Name, &tenant.Subdomain, &tenant.DBName, &tenant.CreatedAt)
		if err != nil {
			continue
		}
		tenants = append(tenants, tenant)
	}

	c.JSON(http.StatusOK, tenants)
}

func GetAdminStats(c *gin.Context) {
	var totalTenants int
	// Exclude the admin tenant from counts
	err := database.DB.QueryRow(context.Background(), "SELECT COUNT(*) FROM tenants WHERE subdomain != 'admin'").Scan(&totalTenants)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stats"})
		return
	}

	// Count tenants created this month (excluding admin)
	var newThisMonth int
	err = database.DB.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM tenants WHERE created_at >= date_trunc('month', CURRENT_DATE) AND subdomain != 'admin'").Scan(&newThisMonth)
	if err != nil {
		newThisMonth = 0
	}

	c.JSON(http.StatusOK, gin.H{
		"total_tenants":  totalTenants,
		"active_tenants": totalTenants, // For now, all are considered active
		"new_this_month": newThisMonth,
	})
}

func ImpersonateTenant(c *gin.Context) {
	id := c.Param("id")

	// 1. Get Tenant Info
	var tenant models.Tenant
	err := database.DB.QueryRow(context.Background(), "SELECT id, name, subdomain, db_name FROM tenants WHERE id = $1", id).Scan(&tenant.ID, &tenant.Name, &tenant.Subdomain, &tenant.DBName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
		return
	}

	// 2. Connect to Tenant DB
	pool, err := database.GetTenantDB(tenant.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant database"})
		return
	}

	// 3. Find Admin User (First user created)
	var user models.User
	var roleName string

	// Join with roles to get role name
	err = pool.QueryRow(context.Background(), `
        SELECT u.id, u.email, r.name 
        FROM users u 
        JOIN roles r ON u.role_id = r.id 
        ORDER BY u.created_at ASC LIMIT 1
    `).Scan(&user.ID, &user.Email, &roleName)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No users found for this tenant"})
		return
	}

	// 4. Generate JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub":       user.ID,
		"tenant_id": tenant.ID,
		"role":      roleName,
		"exp":       time.Now().Add(time.Hour * 1).Unix(), // Short expiration for impersonation
	})

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "default_secret_key"
	}

	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": tokenString,
		"user": gin.H{
			"email": user.Email,
			"role":  roleName,
		},
	})
}

type UpdateSubscriptionRequest struct {
	Tier string `json:"tier" binding:"required,oneof=normal pro premium"`
}

func UpdateTenantSubscription(c *gin.Context) {
	id := c.Param("id")
	var req UpdateSubscriptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update subscription tier in Master DB
	result, err := database.DB.Exec(context.Background(),
		"UPDATE tenants SET subscription_tier = $1 WHERE id = $2",
		req.Tier, id)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update subscription"})
		return
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Subscription updated successfully",
		"tier":    req.Tier,
	})
}
