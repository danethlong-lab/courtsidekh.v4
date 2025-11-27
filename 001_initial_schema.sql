-- Migration: 001_initial_schema.sql
-- Description: Create initial database schema for Courtside booking system
-- Date: 2025-11-27

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    telegram_id BIGINT UNIQUE NOT NULL,
    username VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone_number VARCHAR(20),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    total_bookings INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0.00
);

CREATE INDEX idx_users_telegram_id ON users(telegram_id);
CREATE INDEX idx_users_email ON users(email);

-- ============================================================================
-- COURTS TABLE
-- ============================================================================
CREATE TABLE courts (
    id SERIAL PRIMARY KEY,
    court_number INTEGER NOT NULL,
    court_type VARCHAR(50) NOT NULL, -- 'pickleball' or 'tennis'
    booking_type VARCHAR(50) NOT NULL, -- 'private', 'openplay', 'lesson'
    name VARCHAR(100) NOT NULL,
    capacity INTEGER, -- NULL for unlimited
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(court_number, court_type)
);

CREATE INDEX idx_courts_type ON courts(court_type);
CREATE INDEX idx_courts_booking_type ON courts(booking_type);

-- ============================================================================
-- BOOKINGS TABLE
-- ============================================================================
CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_reference VARCHAR(50) UNIQUE NOT NULL,
    booking_type VARCHAR(50) NOT NULL, -- 'private', 'openplay', 'lesson'
    court_type VARCHAR(50) NOT NULL, -- 'pickleball', 'tennis'
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'confirmed', 'cancelled', 'completed'
    people_count INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'paid', 'refunded', 'failed'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    notes TEXT
);

CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_reference ON bookings(booking_reference);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);

-- ============================================================================
-- BOOKING SLOTS TABLE
-- ============================================================================
CREATE TABLE booking_slots (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    court_id INTEGER NOT NULL REFERENCES courts(id),
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_peak BOOLEAN DEFAULT FALSE,
    slot_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_booking_slots_booking_id ON booking_slots(booking_id);
CREATE INDEX idx_booking_slots_court_date ON booking_slots(court_id, booking_date);
CREATE INDEX idx_booking_slots_date_time ON booking_slots(booking_date, start_time);

-- Prevent double booking on private courts
CREATE UNIQUE INDEX idx_unique_private_slot ON booking_slots(court_id, booking_date, start_time)
WHERE court_id IN (SELECT id FROM courts WHERE booking_type = 'private');

-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    payment_method VARCHAR(50) NOT NULL, -- 'telegram_stars', 'stripe', etc.
    payment_provider_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'refunded'
    telegram_payment_charge_id VARCHAR(255),
    refund_amount DECIMAL(10,2),
    refund_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    refunded_at TIMESTAMP,
    metadata JSONB
);

CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_provider_id ON payments(payment_provider_id);

-- ============================================================================
-- OPEN PLAY CAPACITY TABLE
-- ============================================================================
CREATE TABLE openplay_capacity (
    id BIGSERIAL PRIMARY KEY,
    court_id INTEGER NOT NULL REFERENCES courts(id),
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    current_capacity INTEGER DEFAULT 0,
    max_capacity INTEGER NOT NULL,
    is_peak BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(court_id, booking_date, start_time)
);

CREATE INDEX idx_openplay_date_time ON openplay_capacity(booking_date, start_time);
CREATE INDEX idx_openplay_court_date ON openplay_capacity(court_id, booking_date);

-- ============================================================================
-- GROUP LESSONS TABLE
-- ============================================================================
CREATE TABLE group_lessons (
    id SERIAL PRIMARY KEY,
    court_id INTEGER NOT NULL REFERENCES courts(id),
    day_of_week INTEGER NOT NULL, -- 0=Sunday, 1=Monday, ..., 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_participants INTEGER NOT NULL,
    price_per_person DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(court_id, day_of_week, start_time)
);

-- ============================================================================
-- AVAILABILITY OVERRIDES TABLE
-- ============================================================================
CREATE TABLE availability_overrides (
    id SERIAL PRIMARY KEY,
    court_id INTEGER REFERENCES courts(id), -- NULL = applies to all courts
    override_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    is_available BOOLEAN DEFAULT FALSE,
    reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id)
);

CREATE INDEX idx_overrides_date ON availability_overrides(override_date);
CREATE INDEX idx_overrides_court_date ON availability_overrides(court_id, override_date);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courts_updated_at BEFORE UPDATE ON courts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_group_lessons_updated_at BEFORE UPDATE ON group_lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update user stats when booking is paid
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_status = 'paid' AND OLD.payment_status != 'paid' THEN
        UPDATE users 
        SET 
            total_bookings = total_bookings + 1,
            total_spent = total_spent + NEW.total_amount
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_booking_stats AFTER UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_user_stats();

-- ============================================================================
-- SEED DATA: Insert Courts
-- ============================================================================

-- Pickleball Courts
INSERT INTO courts (court_number, court_type, booking_type, name, capacity) VALUES
(1, 'pickleball', 'private', 'Pickleball Court 1', NULL),
(2, 'pickleball', 'private', 'Pickleball Court 2', NULL),
(3, 'pickleball', 'openplay', 'Pickleball Court 3', 20),
(4, 'pickleball', 'openplay', 'Pickleball Court 4', 20),
(5, 'pickleball', 'openplay', 'Pickleball Court 5', 20);

-- Tennis Courts
INSERT INTO courts (court_number, court_type, booking_type, name, capacity) VALUES
(1, 'tennis', 'private', 'Tennis Court 1', NULL),
(2, 'tennis', 'private', 'Tennis Court 2', NULL);

-- ============================================================================
-- SEED DATA: Insert Group Lessons
-- ============================================================================

-- Tennis Group Lessons: Tuesday, Wednesday, Thursday from 5-6pm on Tennis Court 1
INSERT INTO group_lessons (court_id, day_of_week, start_time, end_time, max_participants, price_per_person) VALUES
((SELECT id FROM courts WHERE court_number = 1 AND court_type = 'tennis'), 2, '17:00:00', '18:00:00', 8, 15.00),
((SELECT id FROM courts WHERE court_number = 1 AND court_type = 'tennis'), 3, '17:00:00', '18:00:00', 8, 15.00),
((SELECT id FROM courts WHERE court_number = 1 AND court_type = 'tennis'), 4, '17:00:00', '18:00:00', 8, 15.00);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Active bookings view
CREATE VIEW active_bookings AS
SELECT 
    b.id,
    b.booking_reference,
    b.user_id,
    u.first_name,
    u.last_name,
    b.booking_type,
    b.court_type,
    b.people_count,
    b.total_amount,
    b.payment_status,
    bs.booking_date,
    bs.start_time,
    bs.end_time,
    c.name as court_name,
    c.court_number
FROM bookings b
JOIN users u ON b.user_id = u.id
JOIN booking_slots bs ON b.id = bs.booking_id
JOIN courts c ON bs.court_id = c.id
WHERE b.status NOT IN ('cancelled')
ORDER BY bs.booking_date, bs.start_time;

-- Daily revenue view
CREATE VIEW daily_revenue AS
SELECT 
    bs.booking_date,
    b.court_type,
    b.booking_type,
    COUNT(DISTINCT b.id) as booking_count,
    SUM(b.total_amount) as total_revenue,
    SUM(b.people_count) as total_people
FROM bookings b
JOIN booking_slots bs ON b.id = bs.booking_id
WHERE b.payment_status = 'paid'
GROUP BY bs.booking_date, b.court_type, b.booking_type
ORDER BY bs.booking_date DESC;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

COMMENT ON TABLE users IS 'Telegram users and customers';
COMMENT ON TABLE courts IS 'Physical courts available for booking';
COMMENT ON TABLE bookings IS 'Main booking records';
COMMENT ON TABLE booking_slots IS 'Individual time slots for each booking';
COMMENT ON TABLE payments IS 'Payment transactions';
COMMENT ON TABLE openplay_capacity IS 'Capacity tracking for open play courts';
COMMENT ON TABLE group_lessons IS 'Recurring group lesson schedules';
COMMENT ON TABLE availability_overrides IS 'Custom availability rules for holidays/maintenance';
