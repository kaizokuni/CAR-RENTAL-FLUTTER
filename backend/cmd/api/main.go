package main

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/handlers"
	"car-rental-backend/internal/middleware"
	"car-rental-backend/internal/models"
	"car-rental-backend/internal/seeder"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize Database
	database.InitDB()
	defer database.CloseDB()

	// Auto-Seed if requested
	if os.Getenv("AUTO_SEED") == "true" {
		seeder.Seed()
	}

	r := gin.Default()

	// Middleware
	// gin.Default() already includes gin.Logger() and gin.Recovery()
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.RateLimitMiddleware())
	// Note: TenantMiddleware is NOT applied globally anymore
	// It's only used on specific routes that need tenant context (e.g., /me endpoint)

	// Public Routes (No tenant resolution needed for login)
	auth := r.Group("/api/v1/auth")
	{
		// auth.POST("/register", handlers.Register) // Disabled: Public registration is closed
		auth.POST("/login", handlers.Login)
	}

	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	protected.Use(middleware.TenantContextMiddleware())
	{
		protected.GET("/me", handlers.Me)

		protected.GET("/cars", handlers.GetCars)
		protected.POST("/cars", handlers.CreateCar)

		protected.GET("/bookings", handlers.GetBookings)
		protected.POST("/bookings", handlers.CreateBooking)
		protected.PUT("/bookings/:id/status", handlers.UpdateBookingStatus)

		protected.GET("/customers", handlers.GetCustomers)
		protected.POST("/customers", handlers.CreateCustomer)

		protected.GET("/financials/expenses", handlers.GetExpenses)
		protected.POST("/financials/expenses", handlers.CreateExpense)
		protected.GET("/financials/invoices", handlers.GetInvoices)
		protected.POST("/financials/invoices", handlers.GenerateInvoice)
		protected.GET("/financials/stats", handlers.GetRevenueStats)

		protected.GET("/notifications", handlers.GetNotifications)
		protected.PUT("/notifications/:id/read", handlers.MarkNotificationRead)

		protected.GET("/reports/utilization", handlers.GetFleetUtilization)
		protected.GET("/reports/revenue-by-car", handlers.GetRevenueByCar)

		// Image upload
		protected.POST("/cars/upload-image", handlers.UploadCarImage)
	}

	// Serve uploaded files
	r.Static("/uploads", "./uploads")

	admin := r.Group("/api/v1/admin")
	// Protect admin routes - require authentication AND super_admin role
	admin.Use(middleware.AuthMiddleware())
	admin.Use(middleware.SuperAdminMiddleware())
	{
		admin.POST("/tenants", handlers.CreateTenant)
		admin.GET("/tenants", handlers.GetAllTenants)
		admin.GET("/tenants/:id", handlers.GetTenant)
		admin.POST("/tenants/:id/impersonate", handlers.ImpersonateTenant)
		admin.DELETE("/tenants/:id", handlers.DeleteTenant)
		admin.GET("/stats", handlers.GetAdminStats)
		admin.PATCH("/tenants/:id/subscription", handlers.UpdateTenantSubscription)
	}

	r.GET("/ping", func(c *gin.Context) {
		tenant, exists := c.Get("tenant")
		tenantName := "unknown"
		if exists {
			tenantName = tenant.(models.Tenant).Name
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "pong",
			"db":      "connected",
			"tenant":  tenantName,
		})
	})

	r.Run() // listen and serve on 0.0.0.0:8080
}
