# Car Rental Management System

A comprehensive car rental management system with multi-tenant support, built with Go backend and Vue.js frontend.

## Project Structure

This repository contains two submodules:

- **`backend/`** - Go/Gin backend API ([back-CarRental](https://github.com/ayoublabrinssi/back-CarRental))
- **`frontend/`** - Vue.js/Vite frontend ([front-CarRental](https://github.com/ayoublabrinssi/front-CarRental))

## Getting Started

### Clone the Repository

```bash
git clone --recursive https://github.com/ayoublabrinssi/CarRental.git
cd CarRental
```

If you already cloned without `--recursive`, initialize submodules:

```bash
git submodule update --init --recursive
```

### Backend Setup

```bash
cd backend
go mod download
go run cmd/api/main.go
```

The backend will run on `http://localhost:8080`

### Frontend Setup

```bash
cd frontend
pnpm install
pnpm dev
```

The frontend will run on `http://localhost:5173`

**Important:** Access via subdomain (e.g., `http://demo.localhost:5173`) for multi-tenancy support.

## Features

- Multi-tenant architecture
- User authentication (JWT)
- Car fleet management
- Booking system
- Customer management
- Financial tracking (invoices, expenses)
- Dark mode support
- Responsive UI with shadcn-vue components

## Technology Stack

### Backend

- Go 1.21+
- Gin Web Framework
- PostgreSQL
- JWT Authentication
- bcrypt for password hashing

### Frontend

- Vue 3 (Composition API)
- TypeScript
- Vite
- Pinia (State Management)
- Vue Router
- shadcn-vue (UI Components)
- Tailwind CSS
- Radix Vue (Headless UI)

## Development

### Updating Submodules

```bash
git submodule update --remote
```

### Working on Submodules

Navigate to the submodule directory and work as normal:

```bash
cd backend
# Make changes
git add .
git commit -m "Your changes"
git push

# Update parent repo
cd ..
git add backend
git commit -m "Update backend submodule"
git push
```

## License

MIT
