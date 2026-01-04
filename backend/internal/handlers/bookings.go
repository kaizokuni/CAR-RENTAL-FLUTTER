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

	// Join with cars and customers to get car and customer details
	query := `
		SELECT 
			b.id, b.car_id, b.start_date, b.end_date, b.status, 
			b.price_per_day * ((b.end_date - b.start_date) + 1) as total_price,
			c.brand, c.model,
			COALESCE(cust.first_name || ' ' || cust.last_name, 'Unknown') as customer_name
		FROM bookings b
		JOIN cars c ON b.car_id = c.id
		LEFT JOIN customers cust ON b.customer_id = cust.id
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
		if err := rows.Scan(&b.ID, &b.CarID, &b.StartDate, &b.EndDate, &b.Status, &b.TotalPrice, &b.CarMake, &b.CarModel, &b.CustomerName); err != nil {
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

	// Find or create customer by name
	var customerID string
	nameParts := splitName(req.CustomerName)
	firstName := nameParts[0]
	lastName := ""
	if len(nameParts) > 1 {
		lastName = nameParts[1]
	}

	// Try to find existing customer
	err = db.QueryRow(context.Background(),
		"SELECT id FROM customers WHERE tenant_id = $1 AND first_name = $2 AND last_name = $3",
		tenant.ID, firstName, lastName).Scan(&customerID)

	if err != nil {
		// Customer not found, create new one
		err = db.QueryRow(context.Background(),
			"INSERT INTO customers (tenant_id, first_name, last_name) VALUES ($1, $2, $3) RETURNING id",
			tenant.ID, firstName, lastName).Scan(&customerID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create customer: " + err.Error()})
			return
		}
	}

	// Calculate price per day from total price and date range
	days := int(req.EndDate.Sub(req.StartDate).Hours()/24) + 1
	if days < 1 {
		days = 1
	}
	pricePerDay := req.TotalPrice / float64(days)

	var bookingID string
	err = db.QueryRow(context.Background(),
		"INSERT INTO bookings (tenant_id, car_id, customer_id, start_date, end_date, price_per_day, status) VALUES ($1, $2, $3, $4, $5, $6, 'available') RETURNING id",
		tenant.ID, req.CarID, customerID, req.StartDate, req.EndDate, pricePerDay).Scan(&bookingID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create booking: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Booking created successfully", "id": bookingID})
}

// splitName splits a full name into first and last name parts
func splitName(fullName string) []string {
	parts := []string{}
	current := ""
	for _, char := range fullName {
		if char == ' ' {
			if current != "" {
				parts = append(parts, current)
				current = ""
			}
		} else {
			current += string(char)
		}
	}
	if current != "" {
		parts = append(parts, current)
	}
	if len(parts) == 0 {
		return []string{fullName}
	}
	if len(parts) == 1 {
		return []string{parts[0], ""}
	}
	// First part is first name, rest joined is last name
	firstName := parts[0]
	lastName := ""
	for i := 1; i < len(parts); i++ {
		if i > 1 {
			lastName += " "
		}
		lastName += parts[i]
	}
	return []string{firstName, lastName}
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
