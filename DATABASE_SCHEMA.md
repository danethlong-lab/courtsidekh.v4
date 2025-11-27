# Database Schema

This document describes the database schema for the Courtside Court Booking System.

## Overview

The system uses PostgreSQL as the primary database. The schema is designed to handle:
- Multiple court types (pickleball, tennis)
- Different booking models (private, open play, lessons)
- User management
- Payment processing
- Availability tracking

## Entity Relationship Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│    users    │────┬───▶│  bookings   │────────▶│  payments   │
└─────────────┘    │    └─────────────┘         └─────────────┘
                   │            │
                   │            │
                   │            ▼
                   │    ┌─────────────┐
                   │    │booking_slots│
                   │    └─────────────┘
                   │            │
                   │            ▼
                   │    ┌─────────────┐
                   └───▶│   courts    │
                        └─────────────┘
```

## Tables

### users

Stores Telegram user information.

```sql
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
```

**Fields:**
- `id`: Internal user ID
- `telegram_id`: Unique Telegram user identifier
- `username`: Telegram username
- `first_name`: User's first name
- `last_name`: User's last name
- `phone_number`: Contact phone number
- `email`: Contact email
- `created_at`: Account creation timestamp
- `updated_at`: Last update timestamp
- `is_active`: Account status
- `is_banned`: Ban status
- `total_bookings`: Lifetime booking count
- `total_spent`: Lifetime spending amount

---

### courts

Defines available courts and their properties.

```sql
CREATE TABLE courts (
    id SERIAL PRIMARY KEY,
    court_number INTEGER NOT NULL,
    court_type VARCHAR(50) NOT NULL, -- 'pickleball' or 'tennis'
    booking_type VARCHAR(50) NOT NULL, -- 'private', 'openplay', 'lesson'
    name VARCHAR(100) NOT NULL,
    capacity INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(court_number, court_type)
);

CREATE INDEX idx_courts_type ON courts(court_type);
CREATE INDEX idx_courts_booking_type ON courts(booking_type);
```

**Fields:**
- `id`: Court ID
- `court_number`: Physical court number (1-7)
- `court_type`: Type of court ('pickleball', 'tennis')
- `booking_type`: Booking model ('private', 'openplay', 'lesson')
- `name`: Display name (e.g., "Pickleball Court 1")
- `capacity`: Maximum capacity (NULL for unlimited)
- `is_active`: Whether court is available for booking
- `created_at`: Record creation timestamp
- `updated_at`: Last update timestamp

**Sample Data:**
```sql
INSERT INTO courts (court_number, court_type, booking_type, name, capacity) VALUES
(1, 'pickleball', 'private', 'Pickleball Court 1', NULL),
(2, 'pickleball', 'private', 'Pickleball Court 2', NULL),
(3, 'pickleball', 'openplay', 'Pickleball Court 3', 20),
(4, 'pickleball', 'openplay', 'Pickleball Court 4', 20),
(5, 'pickleball', 'openplay', 'Pickleball Court 5', 20),
(1, 'tennis', 'private', 'Tennis Court 1', NULL),
(2, 'tennis', 'private', 'Tennis Court 2', NULL);
```

---

### bookings

Main booking records.

```sql
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
```

**Fields:**
- `id`: Booking ID
- `user_id`: Reference to user who made the booking
- `booking_reference`: Unique booking reference (e.g., "BK12345")
- `booking_type`: Type of booking
- `court_type`: Court type
- `status`: Current booking status
- `people_count`: Number of people in the booking
- `total_amount`: Total cost
- `payment_status`: Payment status
- `created_at`: Booking creation time
- `updated_at`: Last update time
- `cancelled_at`: Cancellation timestamp
- `cancellation_reason`: Reason for cancellation
- `notes`: Additional notes

---

### booking_slots

Individual time slots for each booking.

```sql
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
```

**Fields:**
- `id`: Slot ID
- `booking_id`: Reference to parent booking
- `court_id`: Reference to court
- `booking_date`: Date of booking
- `start_time`: Start time (e.g., '09:00:00')
- `end_time`: End time (e.g., '10:00:00')
- `is_peak`: Whether this slot is peak pricing
- `slot_price`: Price for this specific slot
- `created_at`: Record creation time

---

### payments

Payment transaction records.

```sql
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    payment_method VARCHAR(50) NOT NULL, -- 'telegram_stars', 'stripe', etc.
    payment_provider_id VARCHAR(255), -- External payment ID
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
```

**Fields:**
- `id`: Payment ID
- `booking_id`: Reference to booking
- `user_id`: Reference to user
- `amount`: Payment amount
- `currency`: Currency code
- `payment_method`: Payment method used
- `payment_provider_id`: External provider transaction ID
- `status`: Payment status
- `telegram_payment_charge_id`: Telegram Stars charge ID
- `refund_amount`: Amount refunded (if any)
- `refund_reason`: Reason for refund
- `created_at`: Payment initiation time
- `completed_at`: Payment completion time
- `refunded_at`: Refund timestamp
- `metadata`: Additional payment metadata (JSON)

---

### openplay_capacity

Tracks current capacity for open play courts (denormalized for performance).

```sql
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
```

**Fields:**
- `id`: Record ID
- `court_id`: Reference to open play court
- `booking_date`: Date
- `start_time`: Hour start time
- `end_time`: Hour end time
- `current_capacity`: Current number of people booked
- `max_capacity`: Maximum capacity
- `is_peak`: Whether this is peak pricing
- `updated_at`: Last update time

---

### group_lessons

Scheduled group lessons.

```sql
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

-- Tennis Court 1: Tuesday, Wednesday, Thursday from 5-6pm
INSERT INTO group_lessons (court_id, day_of_week, start_time, end_time, max_participants, price_per_person) VALUES
((SELECT id FROM courts WHERE court_number = 1 AND court_type = 'tennis'), 2, '17:00:00', '18:00:00', 8, 15.00),
((SELECT id FROM courts WHERE court_number = 1 AND court_type = 'tennis'), 3, '17:00:00', '18:00:00', 8, 15.00),
((SELECT id FROM courts WHERE court_number = 1 AND court_type = 'tennis'), 4, '17:00:00', '18:00:00', 8, 15.00);
```

**Fields:**
- `id`: Lesson ID
- `court_id`: Reference to court
- `day_of_week`: Day (2=Tuesday, 3=Wednesday, 4=Thursday)
- `start_time`: Start time
- `end_time`: End time
- `max_participants`: Maximum students
- `price_per_person`: Cost per student
- `is_active`: Whether lesson is currently offered

---

### availability_overrides

Custom availability rules (holidays, maintenance, etc.).

```sql
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
```

**Fields:**
- `id`: Override ID
- `court_id`: Specific court (NULL for all)
- `override_date`: Date of override
- `start_time`: Start time (NULL for all day)
- `end_time`: End time (NULL for all day)
- `is_available`: Availability status
- `reason`: Reason for override (e.g., "Maintenance", "Holiday")
- `created_at`: Creation time
- `created_by`: Admin who created override

---

## Indexes

Key indexes for query performance:

```sql
-- User lookups
CREATE INDEX idx_users_telegram_id ON users(telegram_id);

-- Booking searches
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);

-- Availability queries
CREATE INDEX idx_booking_slots_court_date ON booking_slots(court_id, booking_date);
CREATE INDEX idx_booking_slots_date_time ON booking_slots(booking_date, start_time);

-- Payment tracking
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(status);
```

---

## Views

### active_bookings

View of all active (non-cancelled) bookings with slot details.

```sql
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
```

### daily_revenue

View of revenue by date.

```sql
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
```

---

## Triggers

### Update timestamp trigger

Automatically updates `updated_at` field.

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courts_updated_at BEFORE UPDATE ON courts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Update user stats trigger

Updates user statistics when bookings are created/updated.

```sql
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_status = 'paid' THEN
        UPDATE users 
        SET 
            total_bookings = total_bookings + 1,
            total_spent = total_spent + NEW.total_amount
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_booking_stats AFTER INSERT ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_user_stats();
```

---

## Sample Queries

### Get availability for a specific date

```sql
-- Get available private courts for a date
SELECT 
    c.id,
    c.name,
    c.court_number,
    generate_series(7, 21) as hour
FROM courts c
WHERE c.court_type = 'pickleball' 
  AND c.booking_type = 'private'
  AND c.is_active = true
EXCEPT
SELECT 
    bs.court_id,
    c.name,
    c.court_number,
    EXTRACT(HOUR FROM bs.start_time) as hour
FROM booking_slots bs
JOIN courts c ON bs.court_id = c.id
WHERE bs.booking_date = '2025-11-27'
  AND c.booking_type = 'private';
```

### Get open play capacity for a time slot

```sql
SELECT 
    opc.booking_date,
    opc.start_time,
    opc.max_capacity - opc.current_capacity as available_spots,
    opc.is_peak
FROM openplay_capacity opc
WHERE opc.booking_date = '2025-11-27'
  AND opc.start_time = '09:00:00'
  AND opc.current_capacity < opc.max_capacity;
```

### Get user booking history

```sql
SELECT 
    b.booking_reference,
    b.booking_type,
    b.court_type,
    bs.booking_date,
    bs.start_time,
    c.name as court_name,
    b.total_amount,
    b.status
FROM bookings b
JOIN booking_slots bs ON b.id = bs.booking_id
JOIN courts c ON bs.court_id = c.id
WHERE b.user_id = 123
ORDER BY bs.booking_date DESC, bs.start_time DESC;
```

---

## Migration Scripts

See the `/migrations` directory for incremental migration scripts:
- `001_initial_schema.sql` - Initial tables
- `002_add_indexes.sql` - Performance indexes
- `003_add_views.sql` - Database views
- `004_add_triggers.sql` - Automated triggers
- `005_seed_data.sql` - Sample data

---

## Backup Strategy

**Daily Backups:**
```bash
pg_dump -U postgres courtside > backup_$(date +%Y%m%d).sql
```

**Point-in-Time Recovery:**
- Enable WAL archiving
- Automated backups to S3/Cloud Storage
- Retention: 30 days

---

## Performance Considerations

1. **Indexes**: Ensure all foreign keys and frequently queried columns are indexed
2. **Partitioning**: Consider partitioning `booking_slots` by date for large datasets
3. **Caching**: Cache availability queries with Redis
4. **Connection Pooling**: Use connection pooling (pg-pool/SQLAlchemy pooling)
5. **Query Optimization**: Use EXPLAIN ANALYZE for slow queries

---

**Last Updated:** 2025-11-27
