package main

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/handlers"
	"car-rental-backend/internal/middleware"
	"car-rental-backend/internal/models"
	"car-rental-backend/internal/seeder"
	"log"
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
		protected.PUT("/cars/:id", handlers.UpdateCar)
		protected.DELETE("/cars/:id", handlers.DeleteCar)

		protected.GET("/bookings", handlers.GetBookings)
		protected.POST("/bookings", handlers.CreateBooking)
		protected.PUT("/bookings/:id/status", handlers.UpdateBookingStatus)

		protected.GET("/customers", handlers.GetCustomers)
		protected.POST("/customers", handlers.CreateCustomer)

		// Staff management
		protected.GET("/staff", handlers.GetStaff)
		protected.POST("/staff", handlers.CreateStaff)
		protected.PUT("/staff/:id", handlers.UpdateStaff)
		protected.DELETE("/staff/:id", handlers.DeleteStaff)
		protected.GET("/roles", handlers.GetRoles)

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

		// Branding customization
		protected.GET("/branding", handlers.GetBranding)
		protected.PUT("/branding", handlers.UpdateBranding)
		protected.POST("/branding/logo", handlers.UploadLogo)

		// Landing page customization
		protected.GET("/landing-page", handlers.GetLandingPage)
		protected.PUT("/landing-page", handlers.UpdateLandingPage)

		// Booking requests management
		protected.GET("/booking-requests", handlers.GetBookingRequests)
		protected.PUT("/booking-requests/:id/status", handlers.UpdateBookingRequestStatus)
	}

	// Public routes (no auth required)
	public := r.Group("/api/v1/public")
	{
		public.POST("/booking-request", handlers.CreatePublicBookingRequest)
		// Subdomain-based public routes
		public.GET("/landing/:subdomain", handlers.GetPublicLandingBySubdomain)
		public.GET("/cars/:subdomain", handlers.GetPublicCarsBySubdomain)
		public.GET("/cars/:subdomain/:carId", handlers.GetPublicCarDetail)
	}

	// Site routes - admin preview (requires auth, uses tenant context)
	site := r.Group("/api/v1/site")
	site.Use(middleware.AuthMiddleware())
	site.Use(middleware.TenantMiddleware())
	{
		site.GET("/landing", handlers.GetPublicLandingPage)
	}

	// Serve uploaded files with logging
	uploads := r.Group("/uploads")
	uploads.Use(func(c *gin.Context) {
		log.Printf("[STATIC] Serving file: %s", c.Request.URL.Path)
		c.Next()
	})
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
