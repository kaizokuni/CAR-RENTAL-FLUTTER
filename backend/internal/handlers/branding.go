package handlers

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// Branding represents tenant branding settings
type Branding struct {
	TenantID       string `json:"tenant_id"`
	LogoURL        string `json:"logo_url"`
	PrimaryColor   string `json:"primary_color"`
	SecondaryColor string `json:"secondary_color"`
	AccentColor    string `json:"accent_color"`
	UpdatedAt      string `json:"updated_at"`
}

// GetBranding returns the branding settings for the current tenant
func GetBranding(c *gin.Context) {
	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	var branding Branding
	var updatedAt time.Time
	err = pool.QueryRow(context.Background(),
		`SELECT tenant_id, COALESCE(logo_url, ''), COALESCE(primary_color, '#3b82f6'), 
		 COALESCE(secondary_color, '#10b981'), COALESCE(accent_color, ''), updated_at 
		 FROM branding WHERE tenant_id = $1`,
		tenantModel.ID).Scan(&branding.TenantID, &branding.LogoURL, &branding.PrimaryColor,
		&branding.SecondaryColor, &branding.AccentColor, &updatedAt)

	if err != nil {
		// Return default branding if not found
		c.JSON(http.StatusOK, Branding{
			TenantID:       tenantModel.ID,
			LogoURL:        "",
			PrimaryColor:   "#3b82f6",
			SecondaryColor: "#10b981",
			AccentColor:    "",
		})
		return
	}

	branding.UpdatedAt = updatedAt.Format(time.RFC3339)
	c.JSON(http.StatusOK, branding)
}

// UpdateBrandingRequest is the request body for updating branding
type UpdateBrandingRequest struct {
	PrimaryColor   string `json:"primary_color"`
	SecondaryColor string `json:"secondary_color"`
	AccentColor    string `json:"accent_color"`
}

// UpdateBranding updates the branding settings
func UpdateBranding(c *gin.Context) {
	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	var req UpdateBrandingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	_, err = pool.Exec(context.Background(),
		`INSERT INTO branding (tenant_id, primary_color, secondary_color, accent_color, updated_at) 
		 VALUES ($1, $2, $3, $4, NOW()) 
		 ON CONFLICT (tenant_id) DO UPDATE SET 
		 primary_color = $2, secondary_color = $3, accent_color = $4, updated_at = NOW()`,
		tenantModel.ID, req.PrimaryColor, req.SecondaryColor, req.AccentColor)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update branding"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Branding updated successfully"})
}

// UploadLogo handles logo upload and returns the URL
func UploadLogo(c *gin.Context) {
	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	file, header, err := c.Request.FormFile("logo")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
		return
	}
	defer file.Close()

	// Validate file type
	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext != ".png" && ext != ".jpg" && ext != ".jpeg" && ext != ".svg" && ext != ".webp" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Allowed: png, jpg, jpeg, svg, webp"})
		return
	}

	// Create uploads directory if not exists
	uploadDir := "./uploads/logos"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}

	// Generate unique filename
	filename := fmt.Sprintf("%s_%d%s", tenantModel.ID, time.Now().UnixNano(), ext)
	filePath := filepath.Join(uploadDir, filename)

	// Save file
	out, err := os.Create(filePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}
	defer out.Close()

	if _, err := io.Copy(out, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to write file"})
		return
	}

	// Update database
	logoURL := "/uploads/logos/" + filename
	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	_, err = pool.Exec(context.Background(),
		`INSERT INTO branding (tenant_id, logo_url, updated_at) 
		 VALUES ($1, $2, NOW()) 
		 ON CONFLICT (tenant_id) DO UPDATE SET logo_url = $2, updated_at = NOW()`,
		tenantModel.ID, logoURL)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save logo URL"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"logo_url": logoURL,
		"message":  "Logo uploaded successfully",
	})
}
