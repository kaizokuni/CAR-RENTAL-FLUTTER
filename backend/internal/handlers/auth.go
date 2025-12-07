package handlers

import (
	"car-rental-backend/internal/audit"
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type RegisterRequest struct {
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=6"`
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get tenant from context
	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantID := tenant.(models.Tenant).ID

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Insert user
	var userID string
	err = database.DB.QueryRow(context.Background(),
		"INSERT INTO users (tenant_id, email, password_hash, first_name, last_name) VALUES ($1, $2, $3, $4, $5) RETURNING id",
		tenantID, req.Email, string(hashedPassword), req.FirstName, req.LastName).Scan(&userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "User registered successfully", "user_id": userID})
}

func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.Printf("🔍 Login attempt for %s", req.Email)

	// Step 1: Find which tenant this user belongs to
	// Query the master database to find the tenant
	var tenantID string
	var tenantModel models.Tenant

	// First, query all tenants to find which one has this user
	rows, err := database.DB.Query(context.Background(), "SELECT id, name, subdomain, db_name, subscription_tier FROM tenants")
	if err != nil {
		log.Printf("🔒 Failed to query tenants: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	defer rows.Close()

	var foundUser models.User
	var roleName string
	userFound := false

	for rows.Next() {
		var tenant models.Tenant
		err := rows.Scan(&tenant.ID, &tenant.Name, &tenant.Subdomain, &tenant.DBName, &tenant.SubscriptionTier)
		if err != nil {
			continue
		}

		// Try to find the user in this tenant's database
		pool, err := database.GetTenantDB(tenant.DBName)
		if err != nil {
			log.Printf("⚠️  Failed to connect to tenant DB %s: %v", tenant.DBName, err)
			continue
		}

		var user models.User
		err = pool.QueryRow(context.Background(),
			"SELECT id, password_hash, first_name, last_name, role_id FROM users WHERE email = $1 AND tenant_id = $2",
			req.Email, tenant.ID).Scan(&user.ID, &user.PasswordHash, &user.FirstName, &user.LastName, &user.RoleID)

		if err == nil {
			// User found in this tenant!
			foundUser = user
			tenantID = tenant.ID
			tenantModel = tenant

			// Get role name
			err = pool.QueryRow(context.Background(), "SELECT name FROM roles WHERE id = $1", user.RoleID).Scan(&roleName)
			if err != nil {
				log.Printf("⚠️  Failed to fetch role for user %s: %v", user.ID, err)
				roleName = "admin" // Default fallback
			}

			userFound = true
			break
		}
	}

	if !userFound {
		log.Printf("🔒 User not found: %s", req.Email)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	log.Printf("✅ User found: %s in tenant %s (role: %s)", foundUser.ID, tenantID, roleName)

	// Check password
	err = bcrypt.CompareHashAndPassword([]byte(foundUser.PasswordHash), []byte(req.Password))
	if err != nil {
		log.Printf("🔒 Password check failed for %s: %v", req.Email, err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	log.Printf("✅ Login successful for %s", req.Email)

	// Generate JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub":       foundUser.ID,
		"tenant_id": tenantID,
		"role":      roleName,
		"exp":       time.Now().Add(time.Hour * 24).Unix(),
	})

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "default_secret_key" // Fallback for dev
	}

	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	// Log Audit (set tenant and user_id in context for audit)
	c.Set("tenant", &tenantModel)
	c.Set("user_id", foundUser.ID)
	audit.LogAudit(c, "LOGIN", gin.H{"email": req.Email})

	c.JSON(http.StatusOK, gin.H{"token": tokenString})
}

func Me(c *gin.Context) {
	// Get user_id from context (set by AuthMiddleware)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Get tenant_id from JWT token (set by AuthMiddleware)
	tokenTenantID, exists := c.Get("token_tenant_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Tenant ID missing from token"})
		return
	}

	tenantID := tokenTenantID.(string)

	// Fetch tenant details from master database
	var tenantModel models.Tenant
	err := database.DB.QueryRow(context.Background(),
		"SELECT id, name, subdomain, db_name, subscription_tier FROM tenants WHERE id = $1",
		tenantID).Scan(&tenantModel.ID, &tenantModel.Name, &tenantModel.Subdomain, &tenantModel.DBName, &tenantModel.SubscriptionTier)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant not found"})
		return
	}

	// Get tenant database pool
	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	var user models.User
	err = pool.QueryRow(context.Background(),
		"SELECT id, email, first_name, last_name FROM users WHERE id = $1 AND tenant_id = $2",
		userID, tenantID).Scan(&user.ID, &user.Email, &user.FirstName, &user.LastName)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "User not found"})
		return
	}

	// Return both user and tenant info
	c.JSON(http.StatusOK, gin.H{
		"user": user,
		"tenant": gin.H{
			"id":                tenantModel.ID,
			"name":              tenantModel.Name,
			"subdomain":         tenantModel.Subdomain,
			"subscription_tier": tenantModel.SubscriptionTier,
		},
	})
}
