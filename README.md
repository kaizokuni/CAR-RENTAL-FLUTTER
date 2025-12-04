# Car Rental SaaS Platform

A modern, multi-tenant Car Rental SaaS platform built with Go (Backend) and Vue 3 (Frontend).

## 🚀 Features

- **Multi-Tenancy**: Complete tenant isolation with subscription tiers (Normal, Pro, Premium)
- **Super Admin Dashboard**: Manage tenants, subscriptions, and impersonate users
- **Fleet Management**: Full CRUD for vehicle management
- **Authentication**: Secure JWT-based authentication with role-based access control (RBAC)
- **Bookings Management**: Create and manage customer bookings
- **Subscription Tiers**: Normal, Pro, and Premium plans with feature gating
- **Security**: Rate limiting, audit logging, and secure password hashing

## 🛠️ Tech Stack

### Backend

- **Language**: Go (Golang)
- **Framework**: Gin Gonic
- **Database**: PostgreSQL 15 (pgx driver)
- **Authentication**: JWT (golang-jwt)

### Frontend

- **Framework**: Vue 3 (Composition API)
- **Build Tool**: Vite
- **State Management**: Pinia
- **Routing**: Vue Router
- **UI Library**: shadcn-vue (Radix Vue)
- **Styling**: Tailwind CSS

## 🐳 Quick Start with Docker (Recommended)

### Prerequisites

- Docker Desktop installed
- Docker Compose installed

### 1. Clone the Repository

```bash
git clone https://github.com/ayoublabrinssi/CarRental.git
cd CarRental
```

### 2. Start All Services

```bash
docker-compose up -d
```

This will start:

- **PostgreSQL** (port 5432)
- **Backend API** (port 8080)
- **Frontend** (port 5173)
- **PgAdmin** (port 5050) - Database management UI

### 3. Access the Application

| Service         | URL                   | Credentials                |
| --------------- | --------------------- | -------------------------- |
| **Frontend**    | http://localhost:5173 | See default users below    |
| **Backend API** | http://localhost:8080 | -                          |
| **PgAdmin**     | http://localhost:5050 | admin@admin.com / password |

### 4. Default User Accounts

The system auto-seeds with these accounts:

| Role            | Email                   | Password   | Description            |
| --------------- | ----------------------- | ---------- | ---------------------- |
| **Super Admin** | superadmin@platform.com | Secret123! | Platform administrator |
| **Shop Owner**  | admin@ahmedcars.com     | Secret123! | Sample shop owner      |

### 5. Stop Services

```bash
docker-compose down
```

### 6. Reset Everything (Clean Slate)

```bash
docker-compose down -v
docker-compose up -d
```

## 📦 Manual Installation (Without Docker)

### Prerequisites

- Go 1.21+
- Node.js 18+
- PostgreSQL 15+

### Backend Setup

1. Navigate to backend directory:

   ```bash
   cd backend
   ```

2. Install dependencies:

   ```bash
   go mod download
   ```

3. Create `.env` file:

   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=postgres
   DB_NAME=car_rental
   JWT_SECRET=your_super_secret_key
   AUTO_SEED=true
   ```

4. Run the server:
   ```bash
   go run cmd/api/main.go
   ```

### Frontend Setup

1. Navigate to frontend directory:

   ```bash
   cd frontend
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Run development server:
   ```bash
   npm run dev
   ```

## 🏗️ Architecture

### Multi-Tenant System

- **Single Domain Dashboard**: All users access `localhost:5173`
- **Role-Based Features**: UI adapts based on user role (Super Admin, Owner, Assistant)
- **Tenant Isolation**: Each shop has its own database for data separation
- **Subscription Tiers**: Features are gated based on subscription level

### Key Features by Role

#### Super Admin

- View all tenants/shops
- Create new tenants
- Manage subscription tiers
- Impersonate shop owners
- Delete tenants

#### Shop Owner (Admin)

- Full access to their shop's features
- Fleet management
- Bookings management
- Customer management
- Financial reports (Pro/Premium only)

#### Assistant

- Limited access based on permissions
- View-only access to most features

## 📝 API Endpoints

### Authentication

- `POST /api/v1/auth/login` - Login and receive JWT

### Protected Routes (Requires Auth + Tenant Context)

- `GET /api/v1/me` - Get current user info
- `GET /api/v1/cars` - List cars
- `POST /api/v1/cars` - Add a car
- `GET /api/v1/bookings` - List bookings
- `POST /api/v1/bookings` - Create a booking

### Super Admin Routes (Requires Super Admin Role)

- `GET /api/v1/admin/tenants` - List all tenants
- `POST /api/v1/admin/tenants` - Create new tenant
- `GET /api/v1/admin/tenants/:id` - Get tenant details
- `PATCH /api/v1/admin/tenants/:id/subscription` - Update subscription
- `DELETE /api/v1/admin/tenants/:id` - Delete tenant
- `POST /api/v1/admin/tenants/:id/impersonate` - Get impersonation token
- `GET /api/v1/admin/stats` - Platform statistics

## 🔧 Development

### Rebuild Containers After Code Changes

```bash
docker-compose up -d --build
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Access Database

```bash
docker exec -it car_rental_postgres psql -U postgres -d car_rental
```

## 🛡️ Security Features

- **JWT Authentication**: Secure token-based auth
- **Password Hashing**: bcrypt for password storage
- **Rate Limiting**: Prevent API abuse
- **CORS Protection**: Configured for specific origins
- **Audit Logging**: Track critical actions
- **Role-Based Access Control**: Granular permissions

## 📄 License

MIT

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.
