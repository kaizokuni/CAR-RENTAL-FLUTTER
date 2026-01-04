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

type Expense struct {
	ID          string    `json:"id"`
	Amount      float64   `json:"amount"`
	Category    string    `json:"category"`
	Date        time.Time `json:"date"`
	Description string    `json:"description"`
}

type CreateExpenseRequest struct {
	Amount      float64   `json:"amount" binding:"required"`
	Category    string    `json:"category" binding:"required"`
	Date        time.Time `json:"date" binding:"required"`
	Description string    `json:"description"`
}

type Invoice struct {
	ID           string     `json:"id"`
	BookingID    string     `json:"booking_id"`
	Amount       float64    `json:"amount"`
	Status       string     `json:"status"`
	IssuedDate   time.Time  `json:"issued_date"`
	DueDate      *time.Time `json:"due_date"`
	CustomerName string     `json:"customer_name,omitempty"` // Joined
}

type GenerateInvoiceRequest struct {
	BookingID string    `json:"booking_id" binding:"required"`
	Amount    float64   `json:"amount" binding:"required"`
	DueDate   time.Time `json:"due_date"`
}

type RevenueStats struct {
	TotalRevenue  float64 `json:"total_revenue"`
	TotalExpenses float64 `json:"total_expenses"`
	NetProfit     float64 `json:"net_profit"`
}

// Helper to get tenant DB connection (reused logic)
func getTenantDBForFinancials(c *gin.Context) (*pgxpool.Pool, *models.Tenant, error) {
	tenantCtx, exists := c.Get("tenant")
	if !exists {
		return nil, nil, context.Canceled
	}
	tenant := tenantCtx.(*models.Tenant)
	db, err := database.GetTenantDB(tenant.DBName)
	return db, tenant, err
}

func GetExpenses(c *gin.Context) {
	db, _, err := getTenantDBForFinancials(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	rows, err := db.Query(context.Background(), "SELECT id, amount, category, date, description FROM expenses ORDER BY date DESC")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch expenses: " + err.Error()})
		return
	}
	defer rows.Close()

	var expenses []Expense
	for rows.Next() {
		var e Expense
		if err := rows.Scan(&e.ID, &e.Amount, &e.Category, &e.Date, &e.Description); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan expense: " + err.Error()})
			return
		}
		expenses = append(expenses, e)
	}

	if expenses == nil {
		expenses = []Expense{}
	}

	c.JSON(http.StatusOK, expenses)
}

func CreateExpense(c *gin.Context) {
	var req CreateExpenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	db, tenant, err := getTenantDBForFinancials(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	var expenseID string
	err = db.QueryRow(context.Background(),
		"INSERT INTO expenses (tenant_id, amount, category, date, description) VALUES ($1, $2, $3, $4, $5) RETURNING id",
		tenant.ID, req.Amount, req.Category, req.Date, req.Description).Scan(&expenseID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create expense: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Expense created successfully", "id": expenseID})
}

func GetInvoices(c *gin.Context) {
	db, _, err := getTenantDBForFinancials(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	// Join with bookings and customers to get customer name
	query := `
		SELECT i.id, i.booking_id, i.amount, i.status, i.created_at, i.due_date, 
		       COALESCE(cust.first_name || ' ' || cust.last_name, 'Unknown') as customer_name
		FROM invoices i
		JOIN bookings b ON i.booking_id = b.id
		LEFT JOIN customers cust ON b.customer_id = cust.id
		ORDER BY i.created_at DESC
	`
	rows, err := db.Query(context.Background(), query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch invoices: " + err.Error()})
		return
	}
	defer rows.Close()

	var invoices []Invoice
	for rows.Next() {
		var i Invoice
		if err := rows.Scan(&i.ID, &i.BookingID, &i.Amount, &i.Status, &i.IssuedDate, &i.DueDate, &i.CustomerName); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan invoice: " + err.Error()})
			return
		}
		invoices = append(invoices, i)
	}

	if invoices == nil {
		invoices = []Invoice{}
	}

	c.JSON(http.StatusOK, invoices)
}

func GenerateInvoice(c *gin.Context) {
	var req GenerateInvoiceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	db, tenant, err := getTenantDBForFinancials(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	var invoiceID string
	err = db.QueryRow(context.Background(),
		"INSERT INTO invoices (tenant_id, booking_id, amount, due_date) VALUES ($1, $2, $3, $4) RETURNING id",
		tenant.ID, req.BookingID, req.Amount, req.DueDate).Scan(&invoiceID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate invoice: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Invoice generated successfully", "id": invoiceID})
}

func GetRevenueStats(c *gin.Context) {
	db, _, err := getTenantDBForFinancials(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to tenant DB"})
		return
	}

	var stats RevenueStats

	// Calculate Total Revenue (Sum of Paid Invoices or just all Invoices for now? Let's say all for simplicity or just Paid)
	// For MVP let's sum all invoices as "Revenue" and all expenses as "Expenses"
	err = db.QueryRow(context.Background(), "SELECT COALESCE(SUM(amount), 0) FROM invoices").Scan(&stats.TotalRevenue)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to calculate revenue: " + err.Error()})
		return
	}

	err = db.QueryRow(context.Background(), "SELECT COALESCE(SUM(amount), 0) FROM expenses").Scan(&stats.TotalExpenses)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to calculate expenses: " + err.Error()})
		return
	}

	stats.NetProfit = stats.TotalRevenue - stats.TotalExpenses

	c.JSON(http.StatusOK, stats)
}
