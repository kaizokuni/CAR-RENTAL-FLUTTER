package handlers

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// LandingPage represents tenant landing page settings
type LandingPage struct {
	TenantID        string   `json:"tenant_id"`
	HeroTitle       string   `json:"hero_title"`
	HeroSubtitle    string   `json:"hero_subtitle"`
	HeroCtaText     string   `json:"hero_cta_text"`
	HeroBackground  string   `json:"hero_background_url"`
	ShowFeatures    bool     `json:"show_features"`
	ShowFleet       bool     `json:"show_fleet"`
	ShowAbout       bool     `json:"show_about"`
	AboutText       string   `json:"about_text"`
	ContactPhone    string   `json:"contact_phone"`
	ContactEmail    string   `json:"contact_email"`
	ContactAddress  string   `json:"contact_address"`
	WhatsappNumber  string   `json:"whatsapp_number"`
	SocialFacebook  string   `json:"social_facebook"`
	SocialInstagram string   `json:"social_instagram"`
	SocialTiktok    string   `json:"social_tiktok"`
	IsLive          bool     `json:"is_live"`
	SelectedCars    []string `json:"selected_cars"`
	UpdatedAt       string   `json:"updated_at,omitempty"`
}

// BookingRequest represents a public booking request
type BookingRequest struct {
	ID                string `json:"id"`
	TenantID          string `json:"tenant_id"`
	CarID             string `json:"car_id"`
	CarInfo           string `json:"car_info,omitempty"` // Brand + Model for display
	CustomerName      string `json:"customer_name"`
	CustomerPhone     string `json:"customer_phone"`
	CustomerEmail     string `json:"customer_email"`
	PickupDate        string `json:"pickup_date"`
	ReturnDate        string `json:"return_date"`
	PickupLocation    string `json:"pickup_location"`
	DeliveryRequested bool   `json:"delivery_requested"`
	Message           string `json:"message"`
	Status            string `json:"status"` // pending, confirmed, rejected
	CreatedAt         string `json:"created_at"`
}

// GetLandingPage returns landing page settings for a tenant
func GetLandingPage(c *gin.Context) {
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

	var lp LandingPage
	var updatedAt time.Time
	var selectedCarsJSON []byte
	err = pool.QueryRow(context.Background(),
		`SELECT tenant_id, COALESCE(hero_title, 'Welcome to Our Car Rental'), 
		 COALESCE(hero_subtitle, 'Find the perfect car for your journey'),
		 COALESCE(hero_cta_text, 'Browse Cars'), COALESCE(hero_background_url, ''),
		 COALESCE(show_features, true), COALESCE(show_fleet, true), COALESCE(show_about, true),
		 COALESCE(about_text, ''), COALESCE(contact_phone, ''), COALESCE(contact_email, ''),
		 COALESCE(contact_address, ''), COALESCE(whatsapp_number, ''), COALESCE(social_facebook, ''), 
		 COALESCE(social_instagram, ''), COALESCE(social_tiktok, ''), COALESCE(is_live, false),
		 COALESCE(selected_cars, '[]'::jsonb), updated_at
		 FROM landing_pages WHERE tenant_id = $1`,
		tenantModel.ID).Scan(&lp.TenantID, &lp.HeroTitle, &lp.HeroSubtitle, &lp.HeroCtaText,
		&lp.HeroBackground, &lp.ShowFeatures, &lp.ShowFleet, &lp.ShowAbout, &lp.AboutText,
		&lp.ContactPhone, &lp.ContactEmail, &lp.ContactAddress, &lp.WhatsappNumber, &lp.SocialFacebook,
		&lp.SocialInstagram, &lp.SocialTiktok, &lp.IsLive, &selectedCarsJSON, &updatedAt)

	if err != nil {
		// Return defaults if not found
		c.JSON(http.StatusOK, LandingPage{
			TenantID:     tenantModel.ID,
			HeroTitle:    "Welcome to Our Car Rental",
			HeroSubtitle: "Find the perfect car for your journey",
			HeroCtaText:  "Browse Cars",
			ShowFeatures: true,
			ShowFleet:    true,
			ShowAbout:    true,
			SelectedCars: []string{},
		})
		return
	}

	// Parse selected cars JSON
	if len(selectedCarsJSON) > 0 {
		json.Unmarshal(selectedCarsJSON, &lp.SelectedCars)
	}
	if lp.SelectedCars == nil {
		lp.SelectedCars = []string{}
	}

	lp.UpdatedAt = updatedAt.Format(time.RFC3339)
	c.JSON(http.StatusOK, lp)
}

// UpdateLandingPage updates landing page settings
func UpdateLandingPage(c *gin.Context) {
	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	var req LandingPage
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	// Convert selected cars to JSON
	selectedCarsJSON, _ := json.Marshal(req.SelectedCars)
	if req.SelectedCars == nil {
		selectedCarsJSON = []byte("[]")
	}

	_, err = pool.Exec(context.Background(),
		`INSERT INTO landing_pages (tenant_id, hero_title, hero_subtitle, hero_cta_text, 
		 hero_background_url, show_features, show_fleet, show_about, about_text,
		 contact_phone, contact_email, contact_address, whatsapp_number, social_facebook, social_instagram, 
		 social_tiktok, is_live, selected_cars, updated_at) 
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, NOW()) 
		 ON CONFLICT (tenant_id) DO UPDATE SET 
		 hero_title = $2, hero_subtitle = $3, hero_cta_text = $4, hero_background_url = $5,
		 show_features = $6, show_fleet = $7, show_about = $8, about_text = $9,
		 contact_phone = $10, contact_email = $11, contact_address = $12, whatsapp_number = $13,
		 social_facebook = $14, social_instagram = $15, social_tiktok = $16, is_live = $17, 
		 selected_cars = $18, updated_at = NOW()`,
		tenantModel.ID, req.HeroTitle, req.HeroSubtitle, req.HeroCtaText, req.HeroBackground,
		req.ShowFeatures, req.ShowFleet, req.ShowAbout, req.AboutText, req.ContactPhone,
		req.ContactEmail, req.ContactAddress, req.WhatsappNumber, req.SocialFacebook, req.SocialInstagram,
		req.SocialTiktok, req.IsLive, selectedCarsJSON)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update landing page"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Landing page updated successfully"})
}

// GetBookingRequests returns all booking requests for the tenant
func GetBookingRequests(c *gin.Context) {
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

	rows, err := pool.Query(context.Background(),
		`SELECT br.id, br.tenant_id, br.car_id, CONCAT(c.brand, ' ', c.model) as car_info,
		 br.customer_name, br.customer_phone, br.customer_email, br.pickup_date, br.return_date,
		 br.pickup_location, br.delivery_requested, COALESCE(br.message, ''), br.status, br.created_at
		 FROM booking_requests br
		 LEFT JOIN cars c ON br.car_id = c.id
		 ORDER BY br.created_at DESC`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch booking requests"})
		return
	}
	defer rows.Close()

	var requests []BookingRequest
	for rows.Next() {
		var r BookingRequest
		var pickupDate, returnDate, createdAt time.Time
		if err := rows.Scan(&r.ID, &r.TenantID, &r.CarID, &r.CarInfo, &r.CustomerName,
			&r.CustomerPhone, &r.CustomerEmail, &pickupDate, &returnDate, &r.PickupLocation,
			&r.DeliveryRequested, &r.Message, &r.Status, &createdAt); err != nil {
			continue
		}
		r.PickupDate = pickupDate.Format("2006-01-02")
		r.ReturnDate = returnDate.Format("2006-01-02")
		r.CreatedAt = createdAt.Format(time.RFC3339)
		requests = append(requests, r)
	}

	if requests == nil {
		requests = []BookingRequest{}
	}

	c.JSON(http.StatusOK, requests)
}

// UpdateBookingRequestStatus updates the status of a booking request
func UpdateBookingRequestStatus(c *gin.Context) {
	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	requestID := c.Param("id")
	var req struct {
		Status string `json:"status"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Status != "pending" && req.Status != "confirmed" && req.Status != "rejected" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status"})
		return
	}

	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	_, err = pool.Exec(context.Background(),
		`UPDATE booking_requests SET status = $1 WHERE id = $2`,
		req.Status, requestID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Status updated successfully"})
}

// CreatePublicBookingRequest creates a booking request from the public landing page (no auth required)
func CreatePublicBookingRequest(c *gin.Context) {
	// Get tenant from subdomain
	subdomain := c.GetHeader("X-Subdomain")
	if subdomain == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subdomain required"})
		return
	}

	// Find tenant by subdomain
	masterPool := database.DB
	var tenantID, dbName string
	err := masterPool.QueryRow(context.Background(),
		`SELECT id, db_name FROM tenants WHERE subdomain = $1`, subdomain).Scan(&tenantID, &dbName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
		return
	}

	var req struct {
		CarID             string `json:"car_id" binding:"required"`
		CustomerName      string `json:"customer_name" binding:"required"`
		CustomerPhone     string `json:"customer_phone" binding:"required"`
		CustomerEmail     string `json:"customer_email"`
		PickupDate        string `json:"pickup_date" binding:"required"`
		ReturnDate        string `json:"return_date" binding:"required"`
		PickupLocation    string `json:"pickup_location"`
		DeliveryRequested bool   `json:"delivery_requested"`
		Message           string `json:"message"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	pool, err := database.GetTenantDB(dbName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	var id string
	err = pool.QueryRow(context.Background(),
		`INSERT INTO booking_requests (tenant_id, car_id, customer_name, customer_phone, 
		 customer_email, pickup_date, return_date, pickup_location, delivery_requested, message, status)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'pending') RETURNING id`,
		tenantID, req.CarID, req.CustomerName, req.CustomerPhone, req.CustomerEmail,
		req.PickupDate, req.ReturnDate, req.PickupLocation, req.DeliveryRequested, req.Message).Scan(&id)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create booking request"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": id, "message": "Booking request submitted successfully"})
}

// PublicLandingResponse combines landing page settings with branding and cars
type PublicLandingResponse struct {
	LandingPage
	Branding   BrandingPublic `json:"branding"`
	Cars       []CarPublic    `json:"cars"`
	TenantName string         `json:"tenant_name"`
}

type BrandingPublic struct {
	LogoURL        string `json:"logo_url"`
	PrimaryColor   string `json:"primary_color"`
	SecondaryColor string `json:"secondary_color"`
}

type CarPublic struct {
	ID           string   `json:"id"`
	Brand        string   `json:"brand"`
	Model        string   `json:"model"`
	Year         int      `json:"year"`
	DailyRate    float64  `json:"daily_rate"`
	ImageURL     string   `json:"image_url"`
	Images       []string `json:"images"`
	Transmission string   `json:"transmission"`
	FuelType     string   `json:"fuel_type"`
	Seats        int      `json:"seats"`
}

// GetPublicLandingPage returns the public landing page for a tenant
func GetPublicLandingPage(c *gin.Context) {
	// For now, use the authenticated user's tenant
	// In production, this would use subdomain
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

	var lp LandingPage
	var updatedAt time.Time
	var selectedCarsJSON []byte
	err = pool.QueryRow(context.Background(),
		`SELECT tenant_id, COALESCE(hero_title, 'Welcome to Our Car Rental'), 
		 COALESCE(hero_subtitle, 'Find the perfect car for your journey'),
		 COALESCE(hero_cta_text, 'Browse Cars'), COALESCE(hero_background_url, ''),
		 COALESCE(show_features, true), COALESCE(show_fleet, true), COALESCE(show_about, true),
		 COALESCE(about_text, ''), COALESCE(contact_phone, ''), COALESCE(contact_email, ''),
		 COALESCE(contact_address, ''), COALESCE(whatsapp_number, ''), COALESCE(social_facebook, ''), 
		 COALESCE(social_instagram, ''), COALESCE(social_tiktok, ''), COALESCE(is_live, false),
		 COALESCE(selected_cars, '[]'::jsonb), updated_at
		 FROM landing_pages WHERE tenant_id = $1`,
		tenantModel.ID).Scan(&lp.TenantID, &lp.HeroTitle, &lp.HeroSubtitle, &lp.HeroCtaText,
		&lp.HeroBackground, &lp.ShowFeatures, &lp.ShowFleet, &lp.ShowAbout, &lp.AboutText,
		&lp.ContactPhone, &lp.ContactEmail, &lp.ContactAddress, &lp.WhatsappNumber, &lp.SocialFacebook,
		&lp.SocialInstagram, &lp.SocialTiktok, &lp.IsLive, &selectedCarsJSON, &updatedAt)

	if err != nil {
		// Return defaults
		lp = LandingPage{
			TenantID:     tenantModel.ID,
			HeroTitle:    "Welcome to Our Car Rental",
			HeroSubtitle: "Find the perfect car for your journey",
			HeroCtaText:  "Browse Cars",
			ShowFeatures: true,
			ShowFleet:    true,
			ShowAbout:    true,
			SelectedCars: []string{},
		}
	} else {
		json.Unmarshal(selectedCarsJSON, &lp.SelectedCars)
		if lp.SelectedCars == nil {
			lp.SelectedCars = []string{}
		}
		lp.UpdatedAt = updatedAt.Format(time.RFC3339)
	}

	// Get branding
	var branding BrandingPublic
	pool.QueryRow(context.Background(),
		`SELECT COALESCE(logo_url, ''), COALESCE(primary_color, '#3b82f6'), COALESCE(secondary_color, '#10b981')
		 FROM branding WHERE tenant_id = $1`, tenantModel.ID).Scan(&branding.LogoURL, &branding.PrimaryColor, &branding.SecondaryColor)

	// Get selected cars
	var cars []CarPublic
	if len(lp.SelectedCars) > 0 {
		rows, err := pool.Query(context.Background(),
			`SELECT id, brand, model, year, daily_rate, COALESCE(image_url, ''), 
			 COALESCE(transmission, ''), COALESCE(fuel_type, ''), COALESCE(seats, 5)
			 FROM cars WHERE id = ANY($1) AND status = 'available'`, lp.SelectedCars)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var car CarPublic
				rows.Scan(&car.ID, &car.Brand, &car.Model, &car.Year, &car.DailyRate,
					&car.ImageURL, &car.Transmission, &car.FuelType, &car.Seats)
				cars = append(cars, car)
			}
		}
	}
	if cars == nil {
		cars = []CarPublic{}
	}

	response := PublicLandingResponse{
		LandingPage: lp,
		Branding:    branding,
		Cars:        cars,
		TenantName:  tenantModel.Name,
	}

	c.JSON(http.StatusOK, response)
}

// GetPublicLandingBySubdomain returns the public landing page for a tenant by subdomain (no auth)
func GetPublicLandingBySubdomain(c *gin.Context) {
	subdomain := c.Param("subdomain")
	if subdomain == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subdomain required"})
		return
	}

	// Find tenant by subdomain
	masterPool := database.DB
	var tenantID, tenantName, dbName string
	err := masterPool.QueryRow(context.Background(),
		`SELECT id, name, db_name FROM tenants WHERE subdomain = $1`, subdomain).Scan(&tenantID, &tenantName, &dbName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Business not found"})
		return
	}

	pool, err := database.GetTenantDB(dbName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	var lp LandingPage
	var updatedAt time.Time
	var selectedCarsJSON []byte
	err = pool.QueryRow(context.Background(),
		`SELECT tenant_id, COALESCE(hero_title, 'Welcome to Our Car Rental'), 
		 COALESCE(hero_subtitle, 'Find the perfect car for your journey'),
		 COALESCE(hero_cta_text, 'Browse Cars'), COALESCE(hero_background_url, ''),
		 COALESCE(show_features, true), COALESCE(show_fleet, true), COALESCE(show_about, true),
		 COALESCE(about_text, ''), COALESCE(contact_phone, ''), COALESCE(contact_email, ''),
		 COALESCE(contact_address, ''), COALESCE(whatsapp_number, ''), COALESCE(social_facebook, ''), 
		 COALESCE(social_instagram, ''), COALESCE(social_tiktok, ''), COALESCE(is_live, false),
		 COALESCE(selected_cars, '[]'::jsonb), updated_at
		 FROM landing_pages WHERE tenant_id = $1`,
		tenantID).Scan(&lp.TenantID, &lp.HeroTitle, &lp.HeroSubtitle, &lp.HeroCtaText,
		&lp.HeroBackground, &lp.ShowFeatures, &lp.ShowFleet, &lp.ShowAbout, &lp.AboutText,
		&lp.ContactPhone, &lp.ContactEmail, &lp.ContactAddress, &lp.WhatsappNumber, &lp.SocialFacebook,
		&lp.SocialInstagram, &lp.SocialTiktok, &lp.IsLive, &selectedCarsJSON, &updatedAt)

	if err != nil {
		lp = LandingPage{
			TenantID:     tenantID,
			HeroTitle:    "Welcome to " + tenantName,
			HeroSubtitle: "Find the perfect car for your journey",
			HeroCtaText:  "Browse Cars",
			ShowFeatures: true,
			ShowFleet:    true,
			ShowAbout:    true,
			IsLive:       false,
			SelectedCars: []string{},
		}
	} else {
		json.Unmarshal(selectedCarsJSON, &lp.SelectedCars)
		if lp.SelectedCars == nil {
			lp.SelectedCars = []string{}
		}
		lp.UpdatedAt = updatedAt.Format(time.RFC3339)
	}

	// Get branding
	var branding BrandingPublic
	pool.QueryRow(context.Background(),
		`SELECT COALESCE(logo_url, ''), COALESCE(primary_color, '#3b82f6'), COALESCE(secondary_color, '#10b981')
		 FROM branding WHERE tenant_id = $1`, tenantID).Scan(&branding.LogoURL, &branding.PrimaryColor, &branding.SecondaryColor)

	// Get featured cars (selected cars)
	var featuredCars []CarPublic
	if len(lp.SelectedCars) > 0 {
		rows, err := pool.Query(context.Background(),
			`SELECT id, brand, model, year, price_per_day, COALESCE(image_url, ''), 
			 COALESCE(transmission, ''), COALESCE(fuel_type, ''), COALESCE(seats, 5),
			 COALESCE(images, '[]'::jsonb)
			 FROM cars WHERE id = ANY($1) AND tenant_id = $2`, lp.SelectedCars, lp.TenantID)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var car CarPublic
				var imagesJSON []byte
				rows.Scan(&car.ID, &car.Brand, &car.Model, &car.Year, &car.DailyRate,
					&car.ImageURL, &car.Transmission, &car.FuelType, &car.Seats, &imagesJSON)
				json.Unmarshal(imagesJSON, &car.Images)
				featuredCars = append(featuredCars, car)
			}
		}
	}

	// Fallback: If no cars found (either because none selected, or selected ones are deleted/invalid)
	if len(featuredCars) == 0 {
		rows, err := pool.Query(context.Background(),
			`SELECT id, brand, model, year, price_per_day, COALESCE(image_url, ''), 
			 COALESCE(transmission, ''), COALESCE(fuel_type, ''), COALESCE(seats, 5),
			 COALESCE(images, '[]'::jsonb)
			 FROM cars WHERE status ILIKE 'available' AND tenant_id = $1 ORDER BY created_at DESC LIMIT 6`, lp.TenantID)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var car CarPublic
				var imagesJSON []byte
				rows.Scan(&car.ID, &car.Brand, &car.Model, &car.Year, &car.DailyRate,
					&car.ImageURL, &car.Transmission, &car.FuelType, &car.Seats, &imagesJSON)
				json.Unmarshal(imagesJSON, &car.Images)
				featuredCars = append(featuredCars, car)
			}
		}
	}
	if featuredCars == nil {
		featuredCars = []CarPublic{}
	}

	response := PublicLandingResponse{
		LandingPage: lp,
		Branding:    branding,
		Cars:        featuredCars,
		TenantName:  tenantName,
	}

	c.JSON(http.StatusOK, response)
}

// GetPublicCarsBySubdomain returns all available cars for a tenant by subdomain (no auth)
func GetPublicCarsBySubdomain(c *gin.Context) {
	subdomain := c.Param("subdomain")
	if subdomain == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subdomain required"})
		return
	}

	// Find tenant by subdomain
	masterPool := database.DB
	var tenantID, dbName string
	err := masterPool.QueryRow(context.Background(),
		`SELECT id, db_name FROM tenants WHERE subdomain = $1`, subdomain).Scan(&tenantID, &dbName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Business not found"})
		return
	}

	pool, err := database.GetTenantDB(dbName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	// Get all available cars
	rows, err := pool.Query(context.Background(),
		`SELECT id, brand, model, year, price_per_day, COALESCE(image_url, ''), 
		 COALESCE(transmission, ''), COALESCE(fuel_type, ''), COALESCE(seats, 5),
		 COALESCE(images, '[]'::jsonb)
		 FROM cars WHERE status ILIKE 'available' AND tenant_id = $1 ORDER BY brand, model`, tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch cars"})
		return
	}
	defer rows.Close()

	var cars []CarPublic
	for rows.Next() {
		var car CarPublic
		var imagesJSON []byte
		rows.Scan(&car.ID, &car.Brand, &car.Model, &car.Year, &car.DailyRate,
			&car.ImageURL, &car.Transmission, &car.FuelType, &car.Seats, &imagesJSON)
		json.Unmarshal(imagesJSON, &car.Images)
		cars = append(cars, car)
	}

	if cars == nil {
		cars = []CarPublic{}
	}

	c.JSON(http.StatusOK, cars)
}

// GetPublicCarDetail returns a single car's details by subdomain and car ID (no auth)
func GetPublicCarDetail(c *gin.Context) {
	subdomain := c.Param("subdomain")
	carID := c.Param("carId")
	if subdomain == "" || carID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Subdomain and car ID required"})
		return
	}

	// Find tenant by subdomain
	masterPool := database.DB
	var tenantID, dbName string
	err := masterPool.QueryRow(context.Background(),
		`SELECT id, db_name FROM tenants WHERE subdomain = $1`, subdomain).Scan(&tenantID, &dbName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Business not found"})
		return
	}

	pool, err := database.GetTenantDB(dbName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	var car CarPublic
	var imagesJSON []byte
	err = pool.QueryRow(context.Background(),
		`SELECT id, brand, model, year, price_per_day, COALESCE(image_url, ''), 
		 COALESCE(transmission, ''), COALESCE(fuel_type, ''), COALESCE(seats, 5),
		 COALESCE(images, '[]'::jsonb)
		 FROM cars WHERE id = $1 AND tenant_id = $2 AND status ILIKE 'available'`, carID, tenantID).Scan(
		&car.ID, &car.Brand, &car.Model, &car.Year, &car.DailyRate,
		&car.ImageURL, &car.Transmission, &car.FuelType, &car.Seats, &imagesJSON)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Car not found or not available"})
		return
	}
	json.Unmarshal(imagesJSON, &car.Images)

	c.JSON(http.StatusOK, car)
}
