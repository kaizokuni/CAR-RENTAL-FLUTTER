# Car Rental SaaS Platform

A modern, multi-tenant Car Rental SaaS platform built with Go (Backend) and Vue 3 (Frontend).

## 🚀 Features

- **Multi-Tenancy**: Subdomain-based tenant isolation with dedicated databases.
- **Authentication**: Secure JWT-based authentication with role-based access control (RBAC).
- **Car Fleet Management**: Manage cars, models, and availability.
- **Bookings Management**: Create and manage customer bookings with automated price calculation.
- **Customer Management**: Maintain customer profiles and history.
- **Financial Management**: Track revenue, expenses, and generate invoices.
- **Reporting & Analytics**: Visualize fleet utilization and revenue trends.
- **Notifications**: Real-time system notifications.
- **Security**: Rate limiting, audit logging, and secure password hashing.

## 🛠️ Tech Stack

### Backend

- **Language**: Go (Golang)
- **Framework**: Gin Gonic
- **Database**: PostgreSQL 15 (pgx driver)
- **Authentication**: JWT (golang-jwt)
- **Migrations**: Custom SQL schema management

### Frontend

- **Framework**: Vue 3 (Composition API)
- **Build Tool**: Vite
- **State Management**: Pinia
- **Routing**: Vue Router
- **UI Library**: shadcn-vue (Radix Vue)
- **Styling**: Tailwind CSS
- **Icons**: Lucide Vue

## 📦 Installation & Setup

### Prerequisites

- Go 1.21+
- Node.js 18+
- PostgreSQL 15+

### Backend Setup

1.  Navigate to the backend directory:

    ```bash
    cd backend
    ```

2.  Install dependencies:

    ```bash
    go mod download
    ```

3.  Set up environment variables:
    Create a `.env` file (or set system env vars) with:

    ```env
    DB_HOST=localhost
    DB_PORT=5432
    DB_USER=postgres
    DB_PASSWORD=postgres
    DB_NAME=car_rental_saas
    JWT_SECRET=your_super_secret_key
    ```

4.  Run the server:
    ```bash
    go run cmd/api/main.go
    ```
    The server will start on `http://localhost:8080`.

### Frontend Setup

1.  Navigate to the frontend directory:

    ```bash
    cd frontend
    ```

2.  Install dependencies:

    ```bash
    npm install
    ```

3.  Run the development server:
    ```bash
    npm run dev
    ```
    The app will be available at `http://localhost:5173`.

## 🏗️ Architecture

The application follows a **multi-tenant architecture** where each tenant (car rental agency) has its own isolated database schema.

- **Tenant Resolution**: Middleware identifies the tenant based on the subdomain (e.g., `tenant1.localhost`).
- **Database Isolation**: Each tenant gets a dedicated PostgreSQL database created upon registration.
- **Shared Kernel**: Common logic (auth, models) is shared, but data is strictly isolated.

## 📝 API Documentation

### Authentication

- `POST /api/v1/auth/register`: Register a new user.
- `POST /api/v1/auth/login`: Login and receive JWT.

### Core Resources

- `GET /api/v1/cars`: List cars.
- `POST /api/v1/cars`: Add a car.
- `GET /api/v1/bookings`: List bookings.
- `POST /api/v1/bookings`: Create a booking.
- `GET /api/v1/customers`: List customers.
- `POST /api/v1/customers`: Add a customer.

### Financials & Reports

- `GET /api/v1/financials/stats`: Revenue stats.
- `GET /api/v1/reports/utilization`: Fleet utilization.

## 🛡️ Security

- **Rate Limiting**: API is rate-limited to prevent abuse.
- **Audit Logs**: Critical actions are logged for security auditing.
- **Input Validation**: Strict validation on all API inputs.

## 📄 License

MIT
