package handlers

import (
	"car-rental-backend/internal/audit"
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
)

type Car struct {
	ID           string   `json:"id"`
	Make         string   `json:"make"`
	Model        string   `json:"model"`
	Year         int      `json:"year"`
	LicensePlate string   `json:"license_plate"`
	Status       string   `json:"status"`
	PricePerDay  float64  `json:"price_per_day"`
	Currency     string   `json:"currency"`
	ImageURL     string   `json:"image_url"` // Main image
	Images       []string `json:"images"`    // All images
}

type CreateCarRequest struct {
	Make         string   `json:"make" binding:"required"`
	Model        string   `json:"model" binding:"required"`
	Year         int      `json:"year" binding:"required"`
	LicensePlate string   `json:"license_plate" binding:"required"`
	PricePerDay  float64  `json:"price_per_day" binding:"required"`
	Currency     string   `json:"currency"`
	ImageURL     string   `json:"image_url"`
	Images       []string `json:"images"`
}

// ... existing getTenantDB ...

func GetCars(c *gin.Context) {
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenant := tenantCtx.(*models.Tenant)

	db, err := database.GetTenantDB(tenant.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	rows, err := db.Query(context.Background(), "SELECT id, make, model, year, license_plate, status, price_per_day, currency, image_url, images FROM cars ORDER BY created_at DESC")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch cars: " + err.Error()})
		return
	}
	defer rows.Close()

	var cars []Car
	for rows.Next() {
		var car Car
		var imageURL *string
		var currency *string
		var images []string

		if err := rows.Scan(&car.ID, &car.Make, &car.Model, &car.Year, &car.LicensePlate, &car.Status, &car.PricePerDay, &currency, &imageURL, &images); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan car: " + err.Error()})
			return
		}
		if imageURL != nil {
			car.ImageURL = *imageURL
		}
		if currency != nil {
			car.Currency = *currency
		} else {
			car.Currency = "MAD"
		}
		if images == nil {
			car.Images = []string{}
		} else {
			car.Images = images
		}
		cars = append(cars, car)
	}

	if cars == nil {
		cars = []Car{}
	}

	c.JSON(http.StatusOK, cars)
}

func CreateCar(c *gin.Context) {
	var req CreateCarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Default currency
	if req.Currency == "" {
		req.Currency = "MAD"
	}

	tenantCtx, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenant := tenantCtx.(*models.Tenant)

	db, err := database.GetTenantDB(tenant.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	// Set main image from array if not provided but array exists
	if req.ImageURL == "" && len(req.Images) > 0 {
		req.ImageURL = req.Images[0]
	}

	var carID string
	err = db.QueryRow(context.Background(),
		"INSERT INTO cars (tenant_id, make, model, year, license_plate, price_per_day, currency, image_url, images) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id",
		tenant.ID, req.Make, req.Model, req.Year, req.LicensePlate, req.PricePerDay, req.Currency, req.ImageURL, req.Images).Scan(&carID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create car: " + err.Error()})
		return
	}

	audit.LogAudit(c, "CREATE_CAR", gin.H{"make": req.Make, "model": req.Model, "plate": req.LicensePlate})

	c.JSON(http.StatusCreated, gin.H{"id": carID, "message": "Car created successfully"})
}

func UpdateCar(c *gin.Context) {
	carID := c.Param("id")
	var req CreateCarRequest // Reuse create request structure
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tenantCtx, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenant := tenantCtx.(*models.Tenant)

	db, err := database.GetTenantDB(tenant.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	// Update query
	query := `
		UPDATE cars 
		SET make = $1, model = $2, year = $3, license_plate = $4, price_per_day = $5, currency = $6, image_url = $7, images = $8
		WHERE id = $9
	`
	// Ensure main image logic
	if req.ImageURL == "" && len(req.Images) > 0 {
		req.ImageURL = req.Images[0]
	}

	result, err := db.Exec(context.Background(), query,
		req.Make, req.Model, req.Year, req.LicensePlate, req.PricePerDay, req.Currency, req.ImageURL, req.Images, carID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update car: " + err.Error()})
		return
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Car not found"})
		return
	}

	audit.LogAudit(c, "UPDATE_CAR", gin.H{"car_id": carID, "make": req.Make, "year": req.Year})

	c.JSON(http.StatusOK, gin.H{"message": "Car updated successfully"})
}

func DeleteCar(c *gin.Context) {
	carID := c.Param("id")

	tenantCtx, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenant := tenantCtx.(*models.Tenant)

	db, err := database.GetTenantDB(tenant.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	// Optional: Check for existing bookings before delete to prevent orphaned records
	// For now, we'll assume cascading or soft delete logic is preferred, or simple hard delete.
	// User asked for "fix modif and delet", implying simple CRUD first.
	// Let's check if it's rented first?
	// For MVP simplicity: Hard delete. Database constraints (FK) on bookings will fail if referenced.

	_, err = db.Exec(context.Background(), "DELETE FROM cars WHERE id = $1", carID)
	if err != nil {
		// Basic check for constraint violation
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete car (may have active bookings): " + err.Error()})
		return
	}

	audit.LogAudit(c, "DELETE_CAR", gin.H{"car_id": carID})

	c.JSON(http.StatusOK, gin.H{"message": "Car deleted successfully"})
}

// UploadCarImage handles car image uploads
func UploadCarImage(c *gin.Context) {
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenant := tenantCtx.(*models.Tenant)

	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image file provided"})
		return
	}

	// Validate file type
	contentType := file.Header.Get("Content-Type")
	if contentType != "image/jpeg" && contentType != "image/png" && contentType != "image/gif" && contentType != "image/webp" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Only JPEG, PNG, GIF, and WebP allowed"})
		return
	}

	// Create upload directory
	uploadDir := fmt.Sprintf("uploads/cars/%s", tenant.Subdomain)
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}

	// Generate unique filename
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("%s-%d%s", generateRandomString(16), time.Now().UnixNano(), ext)
	filePath := filepath.Join(uploadDir, filename)

	// Save file
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save image"})
		return
	}

	// Return the URL
	imageURL := "/" + filePath
	c.JSON(http.StatusOK, gin.H{"url": imageURL})
}

// Helper function to generate random string
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
		time.Sleep(1 * time.Nanosecond)
	}
	return string(b)
}
