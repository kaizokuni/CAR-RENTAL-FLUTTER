package handlers

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Customer struct {
	ID            string `json:"id"`
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	Email         string `json:"email"`
	Phone         string `json:"phone"`
	LicenseNumber string `json:"license_number"`
	Address       string `json:"address"`
}

type CreateCustomerRequest struct {
	FirstName     string `json:"first_name" binding:"required"`
	LastName      string `json:"last_name" binding:"required"`
	Email         string `json:"email" binding:"required"`
	Phone         string `json:"phone"`
	LicenseNumber string `json:"license_number"`
	Address       string `json:"address"`
}

// Helper to get tenant DB connection (reused logic)
func getTenantDBForCustomers(c *gin.Context) (*pgxpool.Pool, *models.Tenant, error) {
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		return nil, nil, context.Canceled
	}
	tenant := tenantCtx.(*models.Tenant)
	db, err := database.GetTenantDB(tenant.DBName)
	return db, tenant, err
}

func GetCustomers(c *gin.Context) {
	db, _, err := getTenantDBForCustomers(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	rows, err := db.Query(context.Background(), "SELECT id, first_name, last_name, email, phone, address FROM customers ORDER BY created_at DESC")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch customers: " + err.Error()})
		return
	}
	defer rows.Close()

	var customers []Customer
	for rows.Next() {
		var cust Customer
		var email, phone, address *string
		if err := rows.Scan(&cust.ID, &cust.FirstName, &cust.LastName, &email, &phone, &address); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan customer: " + err.Error()})
			return
		}
		if email != nil {
			cust.Email = *email
		}
		if phone != nil {
			cust.Phone = *phone
		}
		if address != nil {
			cust.Address = *address
		}
		customers = append(customers, cust)
	}

	if customers == nil {
		customers = []Customer{}
	}

	c.JSON(http.StatusOK, customers)
}

func CreateCustomer(c *gin.Context) {
	var req CreateCustomerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	db, tenant, err := getTenantDBForCustomers(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	var customerID string
	err = db.QueryRow(context.Background(),
		"INSERT INTO customers (tenant_id, first_name, last_name, email, phone, address) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id",
		tenant.ID, req.FirstName, req.LastName, req.Email, req.Phone, req.Address).Scan(&customerID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create customer: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Customer created successfully", "id": customerID})
}
