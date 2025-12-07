# Car Rental SaaS Platform - Development Roadmap

## Tech Stack: Go + Vue.js + Self-Hosted

## Executive Summary

This roadmap outlines the development of a **multi-tenant SaaS car rental management platform** where each client operates on a separate subdomain with isolated database, custom theme/branding, and dashboard capabilities for fleet management. Built with **Go backend, Vue.js frontend, and self-hosted Linux server infrastructure**.

---

## Technology Stack Specifications

### Frontend Stack

- **Framework:** Vue.js 3 (Composition API)
- **State Management:** Pinia
- **Routing:** Vue Router 4
- **HTTP Client:** fetch
- **UI/Styling:** Tailwind CSS + shadcn-vue UI components
- **Build Tool:** Vite
- **Date Management:** Day.js

### Backend Stack

- **Language:** Go 1.21+
- **Framework:** Gin Gonic or Echo
- **Authentication:** JWT (golang-jwt)
- **Database Driver:** pgx or pq for PostgreSQL
- **Connection Pooling:** pgxpool
- **Middleware:** CORS, Rate Limiting, Request Logging
- **Config Management:** Viper
- **Testing:** Testify, GoConvey

### Database

- **Primary:** PostgreSQL 15+
- **Per Tenant:** Separate database instance per client
- **Backup:** Automated daily backups, stored on self-hosted NAS/backup server
- **Replication:** Optional PostgreSQL streaming replication for HA

### Infrastructure (Self-Hosted)

- **Server OS:** Ubuntu 22.04 LTS or Debian 12
- **Containerization:** Docker + Docker Compose
- **Reverse Proxy:** Nginx
- **SSL/TLS:** Let's Encrypt (Certbot)
- **Process Manager:** Supervisor or Systemd
- **Monitoring:** Prometheus + Grafana (local stack)
- **Log Aggregation:** ELK Stack or Loki (optional)
- **Backup Storage:** NAS or Secondary HD
- **Domain Management:** DNS server or DNS provider (Route53, Namecheap)

---

## Hardware Requirements (Self-Hosted)

### Minimum Setup (MVP)

- **CPU:** 4 cores
- **RAM:** 8GB minimum (16GB recommended)
- **Storage:** 500GB SSD (OS + Docker + Databases)
- **Network:** Gigabit Ethernet, Static IP
- **Backup:** External drive or NAS (1-2TB)

### Recommended Production Setup

- **CPU:** 8-16 cores
- **RAM:** 32GB
- **Storage:**
  - 500GB NVMe SSD (system/apps)
  - 2TB HDD RAID array (database backups)
- **Redundancy:** Secondary server for failover
- **UPS:** Uninterruptible Power Supply
- **Network:** Dual ISP or failover connectivity

---

## Phase 1: Foundation & Infrastructure Setup (Weeks 1-4)

### 1.1 Server & Environment Setup

**Deliverables:**

- Procure/Setup physical or virtual server (Ubuntu 22.04 LTS)
- Configure network (static IP, DNS records)
- SSL/TLS certificate setup (Let's Encrypt)
- Firewall configuration (UFW)
- SSH hardening and key-based authentication

### 1.2 Docker & Containerization

**Deliverables:**

- Install Docker and Docker Compose
- Create Docker network for multi-container setup
- Setup docker-compose.yml for orchestration
- Configure volume mounting for persistent data
- Backup automation scripts

### 1.3 Nginx Reverse Proxy

**Deliverables:**

- Install and configure Nginx
- Setup virtual hosts for subdomain routing
- SSL/TLS termination configuration
- Load balancing rules
- Gzip compression and caching headers

### 1.4 PostgreSQL Setup

**Deliverables:**

- Install PostgreSQL 15 in Docker container
- Master database for tenant metadata
- Backup script (daily automated backups)
- Connection pooling configuration
- Initial schema design

### 1.5 Go Backend Infrastructure

**Deliverables:**

- Go development environment setup
- Gin/Echo project structure scaffolding
- Module initialization (go.mod management)
- Environment configuration files
- Docker build files for Go service

### 1.6 Vue.js Frontend Setup

**Deliverables:**

- Vite + Vue.js 3 project scaffolding
- Tailwind CSS configuration
- Component library structure
- Pinia store setup
- Docker build for frontend SPA

---

## Phase 2: Core Backend Development (Weeks 5-8)

### 2.1 Multi-Tenant Architecture & Authentication

**Features:**

- Tenant identification from subdomain
- Master database for tenant metadata
- JWT token generation and validation
- User registration and login endpoint
- Role-based middleware
- Tenant context injection in all requests

**Go Implementation:**

- `TenantMiddleware` - Extracts tenant from request host
- `AuthMiddleware` - Validates JWT tokens
- `RBACMiddleware` - Checks permissions
- PostgreSQL tables: `tenants`, `users`, `roles`, `permissions`

### 2.2 Tenant Provisioning API

**Endpoints: with api versioning**

- `POST /api/v1/admin/tenants` - Create new tenant
- `GET /api/admin/tenants/{id}` - Get tenant info
- `PUT /api/admin/tenants/{id}` - Update tenant
- `DELETE /api/admin/tenants/{id}` - Delete tenant

**Actions on tenant creation:**

- Create new PostgreSQL database
- Initialize schema
- Create admin user
- Setup default theme
- Generate API credentials

### 2.3 Core API Endpoints Structure

**Go Handlers Pattern:**

```
handlers/
├── auth.go (login, register, refresh token)
├── tenants.go (tenant management)
├── users.go (user management)
├── cars.go (car fleet management)
├── bookings.go (rental bookings)
├── customers.go (customer management)
└── themes.go (theme management)
```

### 2.4 Database Design

**Tenant Management (Master DB):**

- `tenants` - Tenant info, subdomain, db_connection_string
- `users` - Global users (if needed)
- `billing` - Subscription and payment info

**Per-Tenant DB Schema:**

- `users` - Tenant employees/admins
- `roles` - Admin, Manager, Staff
- `permissions` - Feature-level permissions
- `cars` - Fleet inventory
- `bookings` - Rental reservations
- `customers` - Customer info
- `themes` - Custom brand colors/settings
- `audit_logs` - All actions logged

---

## Phase 3: Branding & Theme System (Weeks 9-12)

### 3.1 Theme Management Backend (Go)

**Endpoints:**

- `GET /api/theme` - Get current theme
- `PUT /api/theme` - Update theme colors/branding
- `GET /api/theme/preview` - Preview changes
- `POST /api/theme/reset` - Reset to default

**Theme Data Structure (PostgreSQL):**

```sql
CREATE TABLE themes (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  primary_color VARCHAR(7),
  secondary_color VARCHAR(7),
  accent_color VARCHAR(7),
  logo_url TEXT,
  favicon_url TEXT,
  font_family VARCHAR(100),
  custom_css TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### 3.2 Theme Management Frontend (Vue.js)

**Components:**

- `ThemeBuilder.vue` - Main theme editor
- `ColorPicker.vue` - Color selection component
- `PreviewPanel.vue` - Live preview
- `ThemeTemplates.vue` - Pre-built theme templates

**Features:**

- Drag-and-drop color picker
- Real-time preview
- Accessibility contrast checker
- Reset to default
- Save custom theme

### 3.3 Theme Application

**Implementation:**

- CSS variable injection in Vue.js
- Theme colors applied to all components
- Landing page respects tenant theme
- Dashboard respects tenant theme
- Email templates respect theme

---

## Phase 4: Landing Page Builder (Weeks 13-16)

### 4.1 Landing Page Builder Backend (Go)

**Endpoints:**

- `GET /api/landing-page` - Get current page structure
- `PUT /api/landing-page` - Save page structure
- `POST /api/landing-page/publish` - Publish to live
- `GET /api/landing-page/versions` - Get version history

**Database Table:**

```sql
CREATE TABLE landing_pages (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  slug VARCHAR(100),
  title VARCHAR(255),
  structure JSONB, -- Stores component tree
  published_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### 4.2 Page Builder Frontend (Vue.js)

**Components:**

- `PageBuilder.vue` - Main builder interface
- `ComponentLibrary.vue` - Available components
- `ComponentCanvas.vue` - Drag-and-drop canvas
- `ComponentEditor.vue` - Property editor
- `PagePreview.vue` - Mobile/Desktop preview

**Pre-built Components:**

- Hero Section
- Features Grid
- Pricing Table
- FAQ Accordion
- Testimonials Carousel
- CTA Buttons
- Contact Form
- Image Gallery

### 4.3 Publishing System

**Features:**

- Save drafts
- Publish to live URL (tenant.domain.com/landing)
- Version history with rollback
- A/B testing support (store variants in JSONB)

---

## Phase 5: Dashboard Core Development (Weeks 17-22)

### 5.1 Dashboard Backend - Analytics API (Go)

**Endpoints:**

- `GET /api/dashboard/stats` - Key metrics
- `GET /api/dashboard/revenue` - Revenue data by period
- `GET /api/dashboard/cars` - Car status summary
- `GET /api/dashboard/bookings` - Recent bookings

**Backend Logic:**

- Efficient SQL queries with proper indexing
- Caching with Redis (optional self-hosted)
- Real-time stats via WebSocket (optional)

### 5.2 Dashboard Frontend - Vue.js Components

**Main Dashboard Components:**

- `DashboardHome.vue` - Main overview
- `StatsCards.vue` - Key metrics display
- `RevenueChart.vue` - Line/Bar charts
- `CarStatusWidget.vue` - Car availability
- `BookingsTable.vue` - Recent rentals

**Dashboard Navigation:**

- Sidebar with modules
- Responsive mobile menu
- User profile dropdown

### 5.3 Car Fleet Management Module

**5.3.1 Cars API (Go)**

**Endpoints:**

- `GET /api/cars` - List all cars (with filters, pagination)
- `POST /api/cars` - Add new car
- `GET /api/cars/{id}` - Get car details
- `PUT /api/cars/{id}` - Update car
- `DELETE /api/cars/{id}` - Delete car
- `PUT /api/cars/{id}/status` - Update car status
- `GET /api/cars/{id}/maintenance` - Maintenance history

**Car Data Model (PostgreSQL):**

```sql
CREATE TABLE cars (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  make VARCHAR(100),
  model VARCHAR(100),
  year INT,
  license_plate VARCHAR(20) UNIQUE,
  vin VARCHAR(17) UNIQUE,
  category VARCHAR(50), -- Economy, Comfort, Premium, SUV
  status VARCHAR(20), -- Available, Rented, Maintenance, Unavailable
  price_per_day DECIMAL(10,2),
  images JSONB, -- Array of image URLs
  damage_notes TEXT,
  last_maintenance DATE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);
```

**5.3.2 Cars Frontend (Vue.js)**

**Components:**

- `CarsList.vue` - Table view of all cars
- `CarForm.vue` - Add/Edit car modal
- `CarDetail.vue` - Car detail page
- `CarStatusBadge.vue` - Status indicator
- `CarImageGallery.vue` - Image upload/view

**Features:**

- Search and filter (by status, category, availability)
- Bulk actions (status change, delete)
- Image upload with preview
- Damage documentation
- Quick edit inline

### 5.4 Bookings/Rentals Management

**5.4.1 Bookings API (Go)**

**Endpoints:**

- `GET /api/bookings` - List all bookings (with filters)
- `POST /api/bookings` - Create new booking
- `GET /api/bookings/{id}` - Get booking details
- `PUT /api/bookings/{id}` - Update booking
- `PUT /api/bookings/{id}/status` - Change booking status
- `DELETE /api/bookings/{id}` - Cancel booking
- `GET /api/bookings/{id}/invoice` - Generate invoice

**Booking Data Model:**

```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  customer_id UUID NOT NULL,
  car_id UUID NOT NULL,
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  status VARCHAR(20), -- Pending, Confirmed, Active, Completed, Cancelled
  total_price DECIMAL(10,2),
  payment_status VARCHAR(20), -- Pending, Paid, Refunded
  notes TEXT,
  special_requests TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (car_id) REFERENCES cars(id)
);
```

**5.4.2 Bookings Frontend (Vue.js)**

**Components:**

- `BookingsList.vue` - Table with filters
- `BookingForm.vue` - Create/Edit booking modal
- `BookingDetail.vue` - Booking detail page
- `CalendarView.vue` - Visual calendar of bookings
- `BookingActions.vue` - Quick action buttons

**Calendar Features:**

- Month/Week/Day views
- Color-coded by status
- Drag-to-reschedule (optional)
- Car availability highlighting

### 5.5 Customer Management

**Endpoints:**

- `GET /api/customers` - List all customers
- `POST /api/customers` - Add customer
- `GET /api/customers/{id}` - Get customer details
- `PUT /api/customers/{id}` - Update customer
- `GET /api/customers/{id}/bookings` - Customer booking history

**Database:**

```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(100),
  phone VARCHAR(20),
  license_number VARCHAR(50),
  license_expiry DATE,
  address TEXT,
  city VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP,
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);
```

### 5.6 Financial Management Backend (Go)

**Endpoints:**

- `GET /api/financials/revenue` - Revenue by period
- `GET /api/financials/expenses` - Expense tracking
- `GET /api/financials/invoices` - List invoices
- `POST /api/financials/invoices/{id}/send` - Send invoice

**Invoice Generation:**

- Generate PDF invoices
- Email invoice to customer
- Track payment status

---

## Phase 6: Advanced Features (Weeks 23-28)

### 6.1 Notifications System (Go + Vue.js)

**Backend:**

- Email service integration (SMTP configuration)
- Notification templates
- Scheduled notifications

**Frontend:**

- In-app notification center
- Toast notifications
- Notification preferences

### 6.2 Document Management

**Features:**

- Document upload API
- File storage on server (or NAS)
- License/insurance document tracking
- Rental agreement generation

### 6.3 Reporting System

**Reports Available:**

- Fleet utilization report
- Revenue report (by period)
- Customer acquisition report
- Top/Bottom performing cars
- Maintenance cost analysis

**Export Formats:**

- PDF
- Excel
- CSV

### 6.4 Audit Logging

**Implementation:**

- Log all user actions
- Track who changed what and when
- Audit trail per tenant
- Exportable audit logs

---

## Phase 7: Security & Optimization (Weeks 29-32)

### 7.1 Security Implementation (Go Backend)

**Requirements:**

- Input validation on all endpoints
- SQL injection prevention (prepared statements via pgx)
- XSS protection (Vue.js escaping, HTTP-only cookies)
- CSRF tokens for state-changing operations
- Rate limiting (per IP, per user)
- Password hashing (bcrypt)
- JWT secret rotation
- CORS configuration

**Go Security Packages:**

- `gorilla/csrf` - CSRF protection
- `golang-jwt/jwt` - JWT handling
- `golang.org/x/crypto/bcrypt` - Password hashing

### 7.2 Performance Optimization

**Database:**

- Add indexes on frequently queried columns
- Query optimization for large datasets
- Connection pooling limits

**Backend:**

- Response caching (HTTP cache headers)
- Gzip compression
- Efficient JSON serialization

**Frontend:**

- Code splitting by route (Vue.js lazy loading)
- Image optimization
- CSS/JS minification by Vite
- Browser caching headers

### 7.3 Backup & Disaster Recovery

**Backup Strategy:**

- Daily automated PostgreSQL backups
- Incremental backups (optional)
- Backup verification (restore test weekly)
- Off-site backup (external NAS or cloud)
- Per-tenant backup isolation

**Backup Script (Bash):**

```bash
# Daily backup script for all PostgreSQL databases
# Run via cron job: 0 2 * * * /usr/local/bin/backup-postgres.sh
```

### 7.4 Monitoring & Alerting

**Tools (Self-Hosted):**

- Prometheus - Metrics collection
- Grafana - Dashboard visualization
- AlertManager - Alert routing
- Node Exporter - System metrics
- cAdvisor - Container metrics

**Monitored Metrics:**

- CPU usage
- Memory usage
- Disk space
- Docker container status
- PostgreSQL connection count
- API response times
- Error rates

---

## Phase 8: Testing & QA (Weeks 33-36)

### 8.1 Go Backend Testing

**Test Types:**

- Unit tests (80%+ coverage target)
- Integration tests (API endpoints)
- Database tests (with test DB)
- Load testing (Apache Bench, wrk)

**Testing Framework:**

- `testing` (standard library)
- `testify` (assertions and mocking)

### 8.2 Vue.js Frontend Testing

**Test Types:**

- Component tests (Vitest)
- E2E tests (Playwright or Cypress)
- Visual regression tests

### 8.3 Security Testing

**Activities:**

- OWASP Top 10 validation
- SQL injection testing
- XSS vulnerability testing
- CSRF token validation
- Authentication/Authorization testing

### 8.4 Performance Testing

**Benchmarks:**

- Page load time: < 2 seconds
- API response time: < 200ms
- Dashboard with 1000 cars: < 3 seconds

---

## Phase 9: Deployment & Launch (Weeks 37-40)

### 9.1 Deployment Setup

**Deliverables:**

- Docker Compose production setup
- Nginx configuration files
- SSL certificate setup
- Monitoring stack deployed
- Backup automation running

**docker-compose.yml Structure:**

```yaml
version: "3.8"
services:
  nginx:
    image: nginx:latest
    ports: [80, 443]
    volumes: [nginx.conf, ssl-certs]

  backend:
    build: ./backend
    environment: [DATABASE_URL, JWT_SECRET]
    depends_on: [postgres]

  frontend:
    build: ./frontend
    depends_on: [backend]

  postgres:
    image: postgres:15
    volumes: [pgdata]
    environment: [POSTGRES_PASSWORD]

  prometheus:
    image: prom/prometheus
    volumes: [prometheus.yml]

  grafana:
    image: grafana/grafana
    ports: [3000]
```

### 9.2 Beta Launch

**Pilot Customers:** 2-3 customers
**Duration:** 2-3 weeks
**Focus:** Performance testing, bug fixing, feedback

### 9.3 Production Launch

**Launch Checklist:**

- All tests passing
- Monitoring active
- Backup verified
- SSL certificates installed
- DNS records configured
- Go-live documentation complete

---

## Phase 10: Post-Launch & Scaling (Ongoing)

### 10.1 Monitoring & Maintenance

**Daily Tasks:**

- Check monitoring dashboards
- Review error logs
- Verify backups completed

**Weekly Tasks:**

- Performance analysis
- Security patch updates
- Database maintenance

**Monthly Tasks:**

- Full backup restore test
- Performance optimization review
- Capacity planning

### 10.2 Future Enhancements

**Phase 11+ Features:**

- Mobile app (Flutter - use your expertise!)
- Advanced analytics
- AI-based pricing optimization
- GPS tracking integration
- Fuel management
- Multi-language support
- White-label opportunities

---

## Development Team Structure

**Recommended Team:**

- 2x Go Backend Developers
- 2x Vue.js Frontend Developers
- 1x DevOps/System Administrator (Self-hosted infrastructure)
- 1x QA Engineer
- 1x UI/UX Designer
- 1x Project Manager

---

## Cost Estimation (Self-Hosted)

### Hardware (One-time)

- Server: $2,000-4,000 (or lease $100-200/month)
- Backup NAS: $500-1,500
- UPS: $300-500
- **Total:** $2,800-6,000 (or $400-700/month if leased)

### Annual Operating Costs

- Internet: $100-200/month ($1,200-2,400/year)
- Domain & DNS: $15-30/year
- SSL Certificates: Free (Let's Encrypt)
- Electricity: $50-100/month ($600-1,200/year)
- **Total Annual:** $2,400-4,500

### Development (One-time)

- ~1,500-2,000 development hours
- At $50/hour: $75,000-100,000
- At $100/hour: $150,000-200,000

**Total Investment:** $77,400-204,500 (hardware + development + first year ops)

---

## Technology Advantages: Go + Vue.js + Self-Hosted

### Why Go?

- ✅ Fast compilation and deployment
- ✅ Excellent concurrency (goroutines)
- ✅ Small binary size (easy Docker deployment)
- ✅ Built-in testing framework
- ✅ Great for multi-tenant APIs
- ✅ Low memory footprint

### Why Vue.js?

- ✅ Gentle learning curve
- ✅ Reactive and responsive UI
- ✅ Excellent documentation
- ✅ Vite provides fast development
- ✅ Great for dashboards
- ✅ Easy component reusability

### Why Self-Hosted?

- ✅ Full data control
- ✅ Lower long-term costs
- ✅ Customization freedom
- ✅ No vendor lock-in
- ✅ Better for privacy-conscious customers
- ⚠️ Requires DevOps expertise
- ⚠️ Manual scaling required

---

## Migration from Development to Production

**Key Steps:**

1. Separate dev/prod environments
2. Environment variable management
3. Production database optimization
4. SSL/TLS hardening
5. Firewall configuration
6. Monitoring stack deployment
7. Automated backup verification
8. Load testing before go-live

---

## Troubleshooting & Support Strategy

**Common Self-Hosted Issues:**

- Database connection pooling exhaustion
- Disk space monitoring
- Memory leaks in long-running processes
- Docker container restarts
- Network connectivity issues
- SSL certificate renewal

**Mitigation:**

- Comprehensive monitoring dashboards
- Automated alerting
- Documentation and runbooks
- Regular health checks
- Capacity planning

---

## Next Steps

1. **Finalize infrastructure:** Procure server or setup VPS
2. **Setup development environment:** Docker, Go, Node.js locally
3. **Begin Phase 1:** Server setup and initial Docker orchestration
4. **Create git repositories:** Separate repos for backend, frontend
5. **Define coding standards:** Go/Vue.js style guides
6. **Start Phase 2:** Begin core API development

---

_This roadmap is optimized for Go backend, Vue.js frontend, and self-hosted deployment. Review quarterly and adjust based on performance and scaling needs._
