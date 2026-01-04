package handlers

import (
	"car-rental-backend/internal/audit"
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type Car struct {
	ID           string   `json:"id"`
	Brand        string   `json:"brand"`
	Model        string   `json:"model"`
	Year         int      `json:"year"`
	LicensePlate string   `json:"license_plate"`
	Status       string   `json:"status"`
	PricePerDay  float64  `json:"price_per_day"`
	Category     string   `json:"category"`
	Currency     string   `json:"currency"`
	ImageURL     string   `json:"image_url"` // Main image
	Images       []string `json:"images"`    // All images
	Transmission string   `json:"transmission"`
	FuelType     string   `json:"fuel_type"`
	Seats        int      `json:"seats"`
	Description  string   `json:"description"`
	CreatedAt    string   `json:"created_at"`
}

type CreateCarRequest struct {
	Brand        string   `json:"brand" binding:"required"`
	Model        string   `json:"model" binding:"required"`
	Year         int      `json:"year" binding:"required"`
	LicensePlate string   `json:"license_plate" binding:"required"`
	PricePerDay  float64  `json:"price_per_day" binding:"required"`
	Currency     string   `json:"currency"`
	ImageURL     string   `json:"image_url"`
	Images       []string `json:"images"`
	Transmission string   `json:"transmission"`
	FuelType     string   `json:"fuel_type"`
	Seats        int      `json:"seats"`
	Description  string   `json:"description"`
	Status       string   `json:"status"`
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

	rows, err := db.Query(context.Background(), "SELECT id, brand, model, year, license_plate, status, price_per_day, currency, image_url, images, transmission, fuel_type, seats, description, created_at FROM cars ORDER BY created_at DESC")
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
		var transmission *string
		var fuelType *string
		var seats *int
		var description *string
		var createdAt time.Time

		if err := rows.Scan(&car.ID, &car.Brand, &car.Model, &car.Year, &car.LicensePlate, &car.Status, &car.PricePerDay, &currency, &imageURL, &images, &transmission, &fuelType, &seats, &description, &createdAt); err != nil {
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
		if transmission != nil {
			car.Transmission = *transmission
		}
		if fuelType != nil {
			car.FuelType = *fuelType
		}
		if seats != nil {
			car.Seats = *seats
		} else {
			car.Seats = 5
		}
		if description != nil {
			car.Description = *description
		}
		car.CreatedAt = createdAt.Format(time.RFC3339)
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

	// Create car in tenant DB
	imagesJSON, _ := json.Marshal(req.Images)
	var carID string
	err = db.QueryRow(context.Background(),
		`INSERT INTO cars (tenant_id, brand, model, year, license_plate, price_per_day, currency, image_url, images, transmission, fuel_type, seats, description) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) RETURNING id`,
		tenant.ID, req.Brand, req.Model, req.Year, req.LicensePlate, req.PricePerDay, req.Currency, req.ImageURL, string(imagesJSON), req.Transmission, req.FuelType, req.Seats, req.Description,
	).Scan(&carID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create car: " + err.Error()})
		return
	}

	audit.LogAudit(c, "CREATE_CAR", gin.H{"brand": req.Brand, "model": req.Model, "plate": req.LicensePlate})

	c.JSON(http.StatusCreated, gin.H{"id": carID, "message": "Car created successfully"})
}

type UpdateCarRequest struct {
	Brand        *string   `json:"brand"`
	Model        *string   `json:"model"`
	Year         *int      `json:"year"`
	LicensePlate *string   `json:"license_plate"`
	PricePerDay  *float64  `json:"price_per_day"`
	Currency     *string   `json:"currency"`
	ImageURL     *string   `json:"image_url"`
	Images       *[]string `json:"images"`
	Transmission *string   `json:"transmission"`
	FuelType     *string   `json:"fuel_type"`
	Seats        *int      `json:"seats"`
	Description  *string   `json:"description"`
	Status       *string   `json:"status"`
}

func UpdateCar(c *gin.Context) {
	carID := c.Param("id")
	var req UpdateCarRequest
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

	// Build dynamic UPDATE query based on provided fields
	setClauses := []string{}
	args := []interface{}{}
	argIndex := 1

	if req.Brand != nil {
		setClauses = append(setClauses, fmt.Sprintf("brand = $%d", argIndex))
		args = append(args, *req.Brand)
		argIndex++
	}
	if req.Model != nil {
		setClauses = append(setClauses, fmt.Sprintf("model = $%d", argIndex))
		args = append(args, *req.Model)
		argIndex++
	}
	if req.Year != nil {
		setClauses = append(setClauses, fmt.Sprintf("year = $%d", argIndex))
		args = append(args, *req.Year)
		argIndex++
	}
	if req.LicensePlate != nil {
		setClauses = append(setClauses, fmt.Sprintf("license_plate = $%d", argIndex))
		args = append(args, *req.LicensePlate)
		argIndex++
	}
	if req.PricePerDay != nil {
		setClauses = append(setClauses, fmt.Sprintf("price_per_day = $%d", argIndex))
		args = append(args, *req.PricePerDay)
		argIndex++
	}
	if req.Currency != nil {
		setClauses = append(setClauses, fmt.Sprintf("currency = $%d", argIndex))
		args = append(args, *req.Currency)
		argIndex++
	}
	if req.ImageURL != nil {
		setClauses = append(setClauses, fmt.Sprintf("image_url = $%d", argIndex))
		args = append(args, *req.ImageURL)
		argIndex++
	}
	if req.Images != nil {
		imagesJSON, _ := json.Marshal(*req.Images)
		setClauses = append(setClauses, fmt.Sprintf("images = $%d", argIndex))
		args = append(args, string(imagesJSON))
		argIndex++
	}
	if req.Transmission != nil {
		setClauses = append(setClauses, fmt.Sprintf("transmission = $%d", argIndex))
		args = append(args, *req.Transmission)
		argIndex++
	}
	if req.FuelType != nil {
		setClauses = append(setClauses, fmt.Sprintf("fuel_type = $%d", argIndex))
		args = append(args, *req.FuelType)
		argIndex++
	}
	if req.Seats != nil {
		setClauses = append(setClauses, fmt.Sprintf("seats = $%d", argIndex))
		args = append(args, *req.Seats)
		argIndex++
	}
	if req.Description != nil {
		setClauses = append(setClauses, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}
	if req.Status != nil {
		setClauses = append(setClauses, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *req.Status)
		argIndex++
	}

	// If no fields to update, return error
	if len(setClauses) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	// Build final query
	query := fmt.Sprintf("UPDATE cars SET %s WHERE id = $%d",
		strings.Join(setClauses, ", "), argIndex)
	args = append(args, carID)

	result, err := db.Exec(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update car: " + err.Error()})
		return
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Car not found"})
		return
	}

	audit.LogAudit(c, "UPDATE_CAR", gin.H{"car_id": carID})

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
	log.Println("[UPLOAD] Starting image upload request")

	tenantCtx, exists := c.Get("tenant")
	if !exists {
		log.Println("[UPLOAD ERROR] Tenant context missing")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenant := tenantCtx.(*models.Tenant)
	log.Printf("[UPLOAD] Tenant: %s (%s)", tenant.Name, tenant.Subdomain)

	file, err := c.FormFile("image")
	if err != nil {
		log.Printf("[UPLOAD ERROR] No image file: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image file provided"})
		return
	}
	log.Printf("[UPLOAD] Received file: %s (size: %d bytes)", file.Filename, file.Size)

	// Validate file type
	contentType := file.Header.Get("Content-Type")
	if contentType != "image/jpeg" && contentType != "image/png" && contentType != "image/gif" && contentType != "image/webp" {
		log.Printf("[UPLOAD ERROR] Invalid content type: %s", contentType)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Only JPEG, PNG, GIF, and WebP allowed"})
		return
	}
	log.Printf("[UPLOAD] Content type validated: %s", contentType)

	// SIMPLIFIED: Use flat structure in /app/uploads
	uploadDir := "uploads"
	if err := os.MkdirAll(uploadDir, 0777); err != nil {
		log.Printf("[UPLOAD ERROR] Failed to create directory: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}
	log.Printf("[UPLOAD] Upload directory ready: %s", uploadDir)

	// Generate unique filename: tenant_randomstring_timestamp.ext
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("%s_%s_%d%s", tenant.Subdomain, generateRandomString(12), time.Now().UnixNano(), ext)
	filePath := filepath.Join(uploadDir, filename)
	log.Printf("[UPLOAD] Generated filename: %s", filename)

	// Save file
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		log.Printf("[UPLOAD ERROR] Failed to save file: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save image"})
		return
	}
	log.Printf("[UPLOAD] File saved successfully: %s", filePath)

	// Verify file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		log.Printf("[UPLOAD ERROR] File not found after save: %s", filePath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "File verification failed"})
		return
	}
	log.Printf("[UPLOAD] File verified on disk")

	// Return ABSOLUTE URL for production (backend:8080) or development (localhost:8080)
	host := c.Request.Host
	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}

	// CRITICAL: Return full absolute URL
	imageURL := fmt.Sprintf("%s://%s/uploads/%s", scheme, host, filename)
	log.Printf("[UPLOAD SUCCESS] Returning URL: %s", imageURL)

	c.JSON(http.StatusOK, gin.H{"url": imageURL})
}

// Helper function to generate random string
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, length)
	// Note: rand package auto-seeds since Go 1.20, no need for rand.Seed()
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}
