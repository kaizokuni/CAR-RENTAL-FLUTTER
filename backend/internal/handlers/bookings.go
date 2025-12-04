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

type Booking struct {
	ID           string    `json:"id"`
	CarID        string    `json:"car_id"`
	CustomerName string    `json:"customer_name"`
	StartDate    time.Time `json:"start_date"`
	EndDate      time.Time `json:"end_date"`
	Status       string    `json:"status"`
	TotalPrice   float64   `json:"total_price"`
	CarMake      string    `json:"car_make,omitempty"`  // Joined field
	CarModel     string    `json:"car_model,omitempty"` // Joined field
}

type CreateBookingRequest struct {
	CarID        string    `json:"car_id" binding:"required"`
	CustomerName string    `json:"customer_name" binding:"required"`
	StartDate    time.Time `json:"start_date" binding:"required"`
	EndDate      time.Time `json:"end_date" binding:"required"`
	TotalPrice   float64   `json:"total_price" binding:"required"`
}

type UpdateBookingStatusRequest struct {
	Status string `json:"status" binding:"required"`
}

// Helper to get tenant DB connection (reused from cars.go logic, ideally moved to middleware/utils)
func getTenantDBFromContext(c *gin.Context) (*pgxpool.Pool, *models.Tenant, error) {
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		return nil, nil, context.Canceled
	}
	tenant := tenantCtx.(*models.Tenant)
	db, err := database.GetTenantDB(tenant.DBName)
	return db, tenant, err
}

func GetBookings(c *gin.Context) {
	db, _, err := getTenantDBFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	// Join with cars to get car details
	query := `
		SELECT b.id, b.car_id, b.customer_name, b.start_date, b.end_date, b.status, b.total_price, c.make, c.model
		FROM bookings b
		JOIN cars c ON b.car_id = c.id
		ORDER BY b.created_at DESC
	`
	rows, err := db.Query(context.Background(), query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch bookings: " + err.Error()})
		return
	}
	defer rows.Close()

	var bookings []Booking
	for rows.Next() {
		var b Booking
		if err := rows.Scan(&b.ID, &b.CarID, &b.CustomerName, &b.StartDate, &b.EndDate, &b.Status, &b.TotalPrice, &b.CarMake, &b.CarModel); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan booking: " + err.Error()})
			return
		}
		bookings = append(bookings, b)
	}

	if bookings == nil {
		bookings = []Booking{}
	}

	c.JSON(http.StatusOK, bookings)
}

func CreateBooking(c *gin.Context) {
	var req CreateBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	db, tenant, err := getTenantDBFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	var bookingID string
	err = db.QueryRow(context.Background(),
		"INSERT INTO bookings (tenant_id, car_id, customer_name, start_date, end_date, total_price) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id",
		tenant.ID, req.CarID, req.CustomerName, req.StartDate, req.EndDate, req.TotalPrice).Scan(&bookingID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create booking: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Booking created successfully", "id": bookingID})
}

func UpdateBookingStatus(c *gin.Context) {
	bookingID := c.Param("id")
	var req UpdateBookingStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	db, _, err := getTenantDBFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	_, err = db.Exec(context.Background(), "UPDATE bookings SET status = $1 WHERE id = $2", req.Status, bookingID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update booking status: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Booking status updated"})
}
