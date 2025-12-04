package models

import (
	"time"
)

type Tenant struct {
	ID               string    `json:"id"`
	Name             string    `json:"name"`
	Subdomain        string    `json:"subdomain"`
	DBName           string    `json:"db_name"`
	SubscriptionTier string    `json:"subscription_tier"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}
