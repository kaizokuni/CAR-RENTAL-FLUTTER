CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    subdomain VARCHAR(100) UNIQUE NOT NULL,
    db_name VARCHAR(255) NOT NULL,
    subscription_tier VARCHAR(20) DEFAULT 'normal' CHECK (subscription_tier IN ('normal', 'pro', 'premium')),
    logo_url TEXT,
    payment_method VARCHAR(50) DEFAULT 'online',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role_id UUID REFERENCES roles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS cars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'Available',
    price_per_day DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'MAD',
    category VARCHAR(50),
    images JSONB DEFAULT '[]',
    image_url TEXT,
    transmission VARCHAR(20),
    fuel_type VARCHAR(30),
    seats INTEGER DEFAULT 5,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    user_id UUID REFERENCES users(id), -- Nullable for system-wide notifications
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info', -- info, warning, success, error
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    car_id UUID REFERENCES cars(id),
    customer_id UUID REFERENCES customers(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    price_per_day DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'MAD',
    image_url TEXT, -- Keeping for backward compatibility or single cover
    images TEXT[], -- Array of image URLs
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'rented', 'maintenance')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    category VARCHAR(100) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    booking_id UUID REFERENCES bookings(id),
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending',
    due_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_bookings_car_id ON bookings(car_id);
CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_cars_tenant_id ON cars(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON customers(tenant_id);

-- Branding settings for tenant customization
CREATE TABLE IF NOT EXISTS branding (
    tenant_id UUID PRIMARY KEY,
    logo_url TEXT,
    primary_color VARCHAR(7) DEFAULT '#3b82f6',
    secondary_color VARCHAR(7) DEFAULT '#10b981',
    accent_color VARCHAR(7),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Landing page settings for public tenant page
CREATE TABLE IF NOT EXISTS landing_pages (
    tenant_id UUID PRIMARY KEY,
    hero_title TEXT,
    hero_subtitle TEXT,
    hero_cta_text VARCHAR(50) DEFAULT 'Browse Cars',
    hero_background_url TEXT,
    show_features BOOLEAN DEFAULT true,
    show_fleet BOOLEAN DEFAULT true,
    show_about BOOLEAN DEFAULT true,
    about_text TEXT,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    contact_address TEXT,
    whatsapp_number VARCHAR(20),
    social_facebook TEXT,
    social_instagram TEXT,
    social_tiktok TEXT,
    is_live BOOLEAN DEFAULT false,
    selected_cars JSONB DEFAULT '[]'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Booking requests from public landing page
CREATE TABLE IF NOT EXISTS booking_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID,
    car_id UUID,
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    customer_email VARCHAR(100),
    pickup_date DATE NOT NULL,
    return_date DATE NOT NULL,
    pickup_location TEXT,
    delivery_requested BOOLEAN DEFAULT false,
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_booking_requests_tenant ON booking_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_status ON booking_requests(status);
