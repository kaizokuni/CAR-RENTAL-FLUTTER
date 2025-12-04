package main

import (
	"car-rental-backend/internal/database"
	"context"
	"fmt"
	"log"

	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Initialize Database
	database.InitDB()
	defer database.CloseDB()

	// 1. Create Admin Tenant (if not exists)
	adminSubdomain := "admin"
	adminName := "Platform Admin"
	adminDBName := "tenant_admin"

	var tenantID string
	err := database.DB.QueryRow(context.Background(),
		"INSERT INTO tenants (name, subdomain, db_name) VALUES ($1, $2, $3) ON CONFLICT (subdomain) DO UPDATE SET name = $1 RETURNING id",
		adminName, adminSubdomain, adminDBName).Scan(&tenantID)

	if err != nil {
		log.Fatalf("Failed to create admin tenant: %v", err)
	}

	fmt.Printf("✅ Admin Tenant ID: %s\n", tenantID)

	// 2. Provision Admin Tenant DB
	err = database.CreateTenantDB(adminDBName)
	if err != nil {
		log.Printf("⚠️  Database might already exist: %v", err)
	}

	err = database.MigrateTenantDB(adminDBName)
	if err != nil {
		log.Fatalf("Failed to migrate admin tenant DB: %v", err)
	}

	// 3. Connect to Admin Tenant DB
	pool, err := database.GetTenantDB(adminDBName)
	if err != nil {
		log.Fatalf("Failed to connect to admin tenant DB: %v", err)
	}

	// 4. Ensure Tenant Record exists in Tenant DB
	_, err = pool.Exec(context.Background(),
		"INSERT INTO tenants (id, name, subdomain, db_name) VALUES ($1, $2, $3, $4) ON CONFLICT (id) DO NOTHING",
		tenantID, adminName, adminSubdomain, adminDBName)
	if err != nil {
		log.Fatalf("Failed to sync tenant record: %v", err)
	}

	// 5. Create Admin Role
	var roleID string
	err = pool.QueryRow(context.Background(),
		"INSERT INTO roles (name, description) VALUES ('super_admin', 'Platform Super Administrator') ON CONFLICT (name) DO UPDATE SET description = 'Platform Super Administrator' RETURNING id").Scan(&roleID)
	if err != nil {
		log.Fatalf("Failed to create admin role: %v", err)
	}

	// 6. Create Super Admin User
	email := "superadmin@platform.com"
	password := "Secret123!" // Change this in production!

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)

	var userID string
	err = pool.QueryRow(context.Background(),
		"INSERT INTO users (tenant_id, email, password_hash, first_name, last_name, role_id) VALUES ($1, $2, $3, 'Super', 'Admin', $4) ON CONFLICT (email) DO UPDATE SET password_hash = $3 RETURNING id",
		tenantID, email, string(hashedPassword), roleID).Scan(&userID)

	if err != nil {
		log.Fatalf("Failed to create super admin user: %v", err)
	}

	fmt.Println("\n🎉 Super Admin Setup Complete!")
	fmt.Println("------------------------------------------------")
	fmt.Printf("URL:      http://%s.localhost:5173\n", adminSubdomain)
	fmt.Printf("Email:    %s\n", email)
	fmt.Printf("Password: %s\n", password)
	fmt.Println("------------------------------------------------")
}
