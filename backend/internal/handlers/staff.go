package handlers

import (
	"car-rental-backend/internal/database"
	"car-rental-backend/internal/models"
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// Staff represents a staff member response
type StaffMember struct {
	ID        string `json:"id"`
	Email     string `json:"email"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	RoleID    string `json:"role_id"`
	RoleName  string `json:"role_name"`
	CreatedAt string `json:"created_at"`
}

// Role represents a role
type Role struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

// CreateStaffRequest is the request body for creating staff
type CreateStaffRequest struct {
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=6"`
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
	RoleID    string `json:"role_id" binding:"required"`
}

// UpdateStaffRequest is the request body for updating staff
type UpdateStaffRequest struct {
	Email     *string `json:"email"`
	FirstName *string `json:"first_name"`
	LastName  *string `json:"last_name"`
	RoleID    *string `json:"role_id"`
	Password  *string `json:"password"`
}

// GetStaff returns all staff members for the tenant
func GetStaff(c *gin.Context) {
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
		`SELECT u.id, u.email, u.first_name, u.last_name, u.role_id, r.name as role_name, u.created_at 
		 FROM users u 
		 LEFT JOIN roles r ON u.role_id = r.id 
		 ORDER BY u.created_at DESC`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch staff"})
		return
	}
	defer rows.Close()

	var staff []StaffMember
	for rows.Next() {
		var s StaffMember
		var roleID, roleName *string
		var createdAt time.Time
		if err := rows.Scan(&s.ID, &s.Email, &s.FirstName, &s.LastName, &roleID, &roleName, &createdAt); err != nil {
			continue
		}
		s.CreatedAt = createdAt.Format(time.RFC3339)
		if roleID != nil {
			s.RoleID = *roleID
		}
		if roleName != nil {
			s.RoleName = *roleName
		}
		staff = append(staff, s)
	}

	if staff == nil {
		staff = []StaffMember{}
	}

	c.JSON(http.StatusOK, staff)
}

// CreateStaff creates a new staff member
func CreateStaff(c *gin.Context) {
	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	var req CreateStaffRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	// Check if email already exists
	var existingID string
	err = pool.QueryRow(context.Background(),
		"SELECT id FROM users WHERE email = $1", req.Email).Scan(&existingID)
	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email already exists"})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Insert user
	var userID string
	err = pool.QueryRow(context.Background(),
		`INSERT INTO users (tenant_id, email, password_hash, first_name, last_name, role_id) 
		 VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
		tenantModel.ID, req.Email, string(hashedPassword), req.FirstName, req.LastName, req.RoleID).Scan(&userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create staff member: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": userID, "message": "Staff member created successfully"})
}

// UpdateStaff updates an existing staff member
func UpdateStaff(c *gin.Context) {
	staffID := c.Param("id")

	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	var req UpdateStaffRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	// Build dynamic update query
	updates := []string{}
	args := []interface{}{}
	argIdx := 1

	if req.Email != nil {
		updates = append(updates, fmt.Sprintf("email = $%d", argIdx))
		args = append(args, *req.Email)
		argIdx++
	}
	if req.FirstName != nil {
		updates = append(updates, fmt.Sprintf("first_name = $%d", argIdx))
		args = append(args, *req.FirstName)
		argIdx++
	}
	if req.LastName != nil {
		updates = append(updates, fmt.Sprintf("last_name = $%d", argIdx))
		args = append(args, *req.LastName)
		argIdx++
	}
	if req.RoleID != nil {
		updates = append(updates, fmt.Sprintf("role_id = $%d", argIdx))
		args = append(args, *req.RoleID)
		argIdx++
	}
	if req.Password != nil {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(*req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
			return
		}
		updates = append(updates, fmt.Sprintf("password_hash = $%d", argIdx))
		args = append(args, string(hashedPassword))
		argIdx++
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	args = append(args, staffID, tenantModel.ID)

	query := "UPDATE users SET " + joinStrings(updates, ", ") +
		fmt.Sprintf(" WHERE id = $%d AND tenant_id = $%d", argIdx, argIdx+1)

	_, err = pool.Exec(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update staff member"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Staff member updated successfully"})
}

// DeleteStaff deletes a staff member
func DeleteStaff(c *gin.Context) {
	staffID := c.Param("id")

	tenant, exists := c.Get("tenant")
	if !exists {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Tenant context missing"})
		return
	}
	tenantModel := tenant.(*models.Tenant)

	// Prevent self-deletion
	currentUserID, _ := c.Get("user_id")
	if currentUserID == staffID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You cannot delete yourself"})
		return
	}

	pool, err := database.GetTenantDB(tenantModel.DBName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database connection failed"})
		return
	}

	result, err := pool.Exec(context.Background(),
		"DELETE FROM users WHERE id = $1 AND tenant_id = $2",
		staffID, tenantModel.ID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete staff member"})
		return
	}

	if result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Staff member not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Staff member deleted successfully"})
}

// GetRoles returns all available roles
func GetRoles(c *gin.Context) {
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
		"SELECT id, name, description FROM roles ORDER BY name")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch roles"})
		return
	}
	defer rows.Close()

	var roles []Role
	for rows.Next() {
		var r Role
		var desc *string
		if err := rows.Scan(&r.ID, &r.Name, &desc); err != nil {
			continue
		}
		if desc != nil {
			r.Description = *desc
		}
		roles = append(roles, r)
	}

	if roles == nil {
		roles = []Role{}
	}

	c.JSON(http.StatusOK, roles)
}

// Helper function to join strings
func joinStrings(strs []string, sep string) string {
	if len(strs) == 0 {
		return ""
	}
	result := strs[0]
	for i := 1; i < len(strs); i++ {
		result += sep + strs[i]
	}
	return result
}
