package handlers

import (
	"car-rental-backend/internal/audit"
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Car struct {
	ID           string  `json:"id"`
	Make         string  `json:"make"`
	Model        string  `json:"model"`
	Year         int     `json:"year"`
	LicensePlate string  `json:"license_plate"`
	Status       string  `json:"status"`
	PricePerDay  float64 `json:"price_per_day"`
	ImageURL     string  `json:"image_url"`
}

type CreateCarRequest struct {
	Make         string  `json:"make" binding:"required"`
	Model        string  `json:"model" binding:"required"`
	Year         int     `json:"year" binding:"required"`
	LicensePlate string  `json:"license_plate" binding:"required"`
	PricePerDay  float64 `json:"price_per_day" binding:"required"`
	ImageURL     string  `json:"image_url"`
}

func getTenantDB(c *gin.Context) (*pgxpool.Pool, error) {
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		return nil, context.Canceled // Or some error indicating missing tenant
	}
	tenant := tenantCtx.(*models.Tenant)
	return database.GetTenantDB(tenant.DBName)
}

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

	rows, err := db.Query(context.Background(), "SELECT id, make, model, year, license_plate, status, price_per_day, image_url FROM cars")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch cars: " + err.Error()})
		return
	}
	defer rows.Close()

	var cars []Car
	for rows.Next() {
		var car Car
		// Handle potential NULLs if schema allows, but here we defined NOT NULL mostly
		var imageURL *string
		if err := rows.Scan(&car.ID, &car.Make, &car.Model, &car.Year, &car.LicensePlate, &car.Status, &car.PricePerDay, &imageURL); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan car: " + err.Error()})
			return
		}
		if imageURL != nil {
			car.ImageURL = *imageURL
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

	var carID string
	err = db.QueryRow(context.Background(),
		"INSERT INTO cars (tenant_id, make, model, year, license_plate, price_per_day, image_url) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id",
		tenant.ID, req.Make, req.Model, req.Year, req.LicensePlate, req.PricePerDay, req.ImageURL).Scan(&carID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create car: " + err.Error()})
		return
	}

	audit.LogAudit(c, "CREATE_CAR", gin.H{"make": req.Make, "model": req.Model, "plate": req.LicensePlate})

	c.JSON(http.StatusCreated, gin.H{"id": carID, "message": "Car created successfully"})
}
