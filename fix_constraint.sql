-- Complete migration: drop old constraint and add new one
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;
ALTER TABLE bookings ALTER COLUMN status SET DEFAULT 'pending';
ALTER TABLE bookings ADD CONSTRAINT bookings_status_check CHECK (status IN ('pending', 'confirmed', 'active', 'completed', 'cancelled'));

-- Update any existing old statuses to new ones
UPDATE bookings SET status = 'pending' WHERE status = 'available';
UPDATE bookings SET status = 'active' WHERE status = 'rented';
UPDATE bookings SET status = 'completed' WHERE status = 'maintenance';
