package database

import (
	"context"
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	DB          *pgxpool.Pool
	tenantPools = make(map[string]*pgxpool.Pool)
	poolMutex   sync.RWMutex
)

func InitDB() {
	// Read from environment variables with sensible defaults
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "postgres"
	}
	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		dbPassword = "password"
	}
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "car_rental"
	}

	// Build connection string from environment variables
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable", dbUser, dbPassword, dbHost, dbPort, dbName)

	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		log.Fatalf("Unable to parse database URL: %v\n", err)
	}

	config.MaxConns = 10
	config.MinConns = 2
	config.MaxConnLifetime = time.Hour
	config.MaxConnIdleTime = 30 * time.Minute

	DB, err = pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		log.Fatalf("Unable to create connection pool: %v\n", err)
	}

	if err := DB.Ping(context.Background()); err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}

	fmt.Println("Successfully connected to the database!")

	// Execute Schema
	schema, err := os.ReadFile("internal/database/schema.sql")
	if err != nil {
		log.Fatalf("Unable to read schema file: %v\n", err)
	}

	_, err = DB.Exec(context.Background(), string(schema))
	if err != nil {
		log.Fatalf("Unable to execute schema: %v\n", err)
	}

	fmt.Println("Schema executed successfully!")
}

func CreateTenantDB(dbName string) error {
	// Connect to default DB to execute CREATE DATABASE
	// Note: We cannot use prepared statements for CREATE DATABASE
	_, err := DB.Exec(context.Background(), fmt.Sprintf("CREATE DATABASE %s", dbName))
	if err != nil {
		return fmt.Errorf("failed to create database: %v", err)
	}
	return nil
}

func MigrateTenantDB(dbName string) error {
	// Build DSN from environment variables (same as InitDB)
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "postgres"
	}
	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		dbPassword = "password"
	}

	tenantDSN := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable", dbUser, dbPassword, dbHost, dbPort, dbName)

	config, err := pgxpool.ParseConfig(tenantDSN)
	if err != nil {
		return fmt.Errorf("failed to parse tenant DSN: %v", err)
	}

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return fmt.Errorf("failed to connect to tenant DB: %v", err)
	}
	defer pool.Close()

	// Read tenant schema
	// For now, we'll use the same schema.sql but ideally we should have a separate one
	schema, err := os.ReadFile("internal/database/schema.sql")
	if err != nil {
		return fmt.Errorf("failed to read schema file: %v", err)
	}

	_, err = pool.Exec(context.Background(), string(schema))
	if err != nil {
		return fmt.Errorf("failed to execute schema on tenant DB: %v", err)
	}

	return nil
}

func GetTenantDB(dbName string) (*pgxpool.Pool, error) {
	poolMutex.RLock()
	pool, exists := tenantPools[dbName]
	poolMutex.RUnlock()

	if exists {
		return pool, nil
	}

	poolMutex.Lock()
	defer poolMutex.Unlock()

	// Double check
	if pool, exists := tenantPools[dbName]; exists {
		return pool, nil
	}

	// Build DSN from environment variables (same as InitDB)
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}
	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "5432"
	}
	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "postgres"
	}
	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		dbPassword = "password"
	}

	tenantDSN := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable", dbUser, dbPassword, dbHost, dbPort, dbName)

	config, err := pgxpool.ParseConfig(tenantDSN)
	if err != nil {
		return nil, fmt.Errorf("failed to parse tenant DSN: %v", err)
	}

	// Config for tenant pools (maybe lighter?)
	config.MaxConns = 5
	config.MinConns = 1

	newPool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to tenant DB: %v", err)
	}

	tenantPools[dbName] = newPool
	return newPool, nil
}

func CloseDB() {
	if DB != nil {
		DB.Close()
	}
	poolMutex.Lock()
	defer poolMutex.Unlock()
	for _, pool := range tenantPools {
		pool.Close()
	}
}
