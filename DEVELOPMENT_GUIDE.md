# Development Guide

Complete guide for setting up and developing the Courtside Court Booking System.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Project Structure](#project-structure)
4. [Development Workflow](#development-workflow)
5. [Telegram Bot Setup](#telegram-bot-setup)
6. [Database Management](#database-management)
7. [Testing](#testing)
8. [Deployment](#deployment)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

1. **Node.js** (v18 or higher)
   ```bash
   # Check version
   node --version
   
   # Install via nvm (recommended)
   nvm install 18
   nvm use 18
   ```

2. **PostgreSQL** (v14 or higher)
   ```bash
   # Check version
   psql --version
   
   # Install on macOS
   brew install postgresql@15
   
   # Install on Ubuntu
   sudo apt-get install postgresql-15
   ```

3. **Git**
   ```bash
   git --version
   ```

4. **Docker & Docker Compose** (optional but recommended)
   ```bash
   docker --version
   docker-compose --version
   ```

### Optional Tools

- **Postman** or **Insomnia** - API testing
- **pgAdmin** or **DBeaver** - Database management
- **VSCode** - Recommended IDE

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/courtside-booking.git
cd courtside-booking
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up Environment Variables

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your settings
nano .env
```

**Required Variables:**
```env
TELEGRAM_BOT_TOKEN=your_bot_token
DATABASE_URL=postgresql://user:password@localhost:5432/courtside
```

### 4. Set Up Database

**Option A: Using Docker (Recommended)**
```bash
# Start PostgreSQL with Docker Compose
docker-compose up -d postgres

# Wait for database to be ready
sleep 5

# Run migrations
npm run migrate
```

**Option B: Local PostgreSQL**
```bash
# Create database
createdb courtside

# Run migrations
npm run migrate

# Seed initial data
npm run seed
```

### 5. Start Development Server

```bash
npm run dev
```

The application should now be running on `http://localhost:3000`

---

## Project Structure

```
courtside-booking/
├── src/
│   ├── bot/                    # Telegram bot implementation
│   │   ├── handlers/           # Message and callback handlers
│   │   │   ├── start.js        # /start command
│   │   │   ├── booking.js      # Booking flow handlers
│   │   │   ├── payment.js      # Payment handlers
│   │   │   ├── mybookings.js   # View bookings
│   │   │   └── cancel.js       # Cancellation flow
│   │   ├── keyboards/          # Telegram keyboard layouts
│   │   │   ├── main.js         # Main menu
│   │   │   ├── booking.js      # Booking keyboards
│   │   │   └── calendar.js     # Calendar view
│   │   ├── middleware/         # Bot middleware
│   │   │   ├── auth.js         # User authentication
│   │   │   └── logging.js      # Request logging
│   │   └── index.js            # Bot initialization
│   │
│   ├── api/                    # REST API
│   │   ├── routes/             # API routes
│   │   │   ├── availability.js # Availability endpoints
│   │   │   ├── bookings.js     # Booking endpoints
│   │   │   ├── payments.js     # Payment endpoints
│   │   │   ├── courts.js       # Court management
│   │   │   └── users.js        # User management
│   │   ├── middleware/         # API middleware
│   │   │   ├── auth.js         # JWT authentication
│   │   │   ├── validation.js   # Request validation
│   │   │   ├── rateLimit.js    # Rate limiting
│   │   │   └── errorHandler.js # Error handling
│   │   └── index.js            # API setup
│   │
│   ├── services/               # Business logic
│   │   ├── bookingService.js   # Booking operations
│   │   ├── availabilityService.js # Availability checks
│   │   ├── pricingService.js   # Price calculations
│   │   ├── paymentService.js   # Payment processing
│   │   └── notificationService.js # Notifications
│   │
│   ├── models/                 # Database models
│   │   ├── Court.js            # Court model
│   │   ├── Booking.js          # Booking model
│   │   ├── User.js             # User model
│   │   ├── Payment.js          # Payment model
│   │   └── index.js            # Model exports
│   │
│   ├── db/                     # Database utilities
│   │   ├── connection.js       # DB connection pool
│   │   ├── migrate.js          # Migration runner
│   │   ├── rollback.js         # Rollback utility
│   │   └── seed.js             # Seed data
│   │
│   ├── utils/                  # Utility functions
│   │   ├── dateHelper.js       # Date utilities
│   │   ├── validation.js       # Input validation
│   │   ├── logger.js           # Logging setup
│   │   └── constants.js        # App constants
│   │
│   ├── config/                 # Configuration
│   │   ├── database.js         # DB config
│   │   ├── telegram.js         # Bot config
│   │   └── app.js              # App config
│   │
│   └── index.js                # Application entry point
│
├── migrations/                 # Database migrations
│   ├── 001_initial_schema.sql
│   ├── 002_add_indexes.sql
│   └── ...
│
├── tests/                      # Test files
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── fixtures/               # Test data
│
├── docs/                       # Documentation
│   ├── API.md
│   ├── DATABASE_SCHEMA.md
│   └── BOOKING_FLOW.md
│
├── logs/                       # Application logs
├── .env.example                # Environment template
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── package.json
└── README.md
```

---

## Development Workflow

### Starting Development

```bash
# Start all services with Docker
docker-compose up -d

# Or start just the app in dev mode
npm run dev

# View logs
docker-compose logs -f app
```

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code
   - Add tests
   - Update documentation

3. **Test your changes**
   ```bash
   npm test
   npm run lint
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**

### Code Style

The project uses ESLint and Prettier:

```bash
# Check for linting errors
npm run lint

# Fix linting errors automatically
npm run lint:fix

# Format code
npm run format
```

---

## Telegram Bot Setup

### 1. Create a Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot` command
3. Follow the prompts to set bot name and username
4. Copy the bot token provided

### 2. Configure Bot Settings

```bash
# Send these commands to @BotFather:

# Set bot description
/setdescription
# Then paste: Book courts at Courtside - Pickleball & Tennis

# Set bot commands
/setcommands
# Then paste:
start - Start the bot
book - Book a court
mybookings - View my bookings
cancel - Cancel a booking
help - Get help
```

### 3. Set Up Payments

1. Contact [@BotFather](https://t.me/BotFather)
2. Send `/mybots`
3. Select your bot
4. Select "Payments"
5. Choose payment provider (Telegram Stars recommended)
6. Copy the payment token

### 4. Test the Bot

```bash
# Add bot token to .env
TELEGRAM_BOT_TOKEN=your_token_here
TELEGRAM_PAYMENT_PROVIDER_TOKEN=your_payment_token_here

# Start the application
npm run dev

# Open Telegram and send /start to your bot
```

---

## Database Management

### Running Migrations

```bash
# Run all pending migrations
npm run migrate

# Rollback last migration
npm run migrate:rollback

# Seed database with test data
npm run seed
```

### Creating a New Migration

1. Create a new SQL file in `migrations/` directory:
   ```bash
   touch migrations/003_add_new_feature.sql
   ```

2. Write your migration:
   ```sql
   -- migrations/003_add_new_feature.sql
   
   CREATE TABLE new_table (
       id SERIAL PRIMARY KEY,
       name VARCHAR(255) NOT NULL
   );
   ```

3. Run the migration:
   ```bash
   npm run migrate
   ```

### Connecting to Database

```bash
# Using psql
psql postgresql://user:password@localhost:5432/courtside

# Using Docker
docker-compose exec postgres psql -U postgres -d courtside
```

### Common Queries

```sql
-- Check active bookings
SELECT * FROM active_bookings WHERE booking_date >= CURRENT_DATE;

-- Check daily revenue
SELECT * FROM daily_revenue WHERE booking_date >= CURRENT_DATE - INTERVAL '7 days';

-- Check open play capacity
SELECT * FROM openplay_capacity 
WHERE booking_date = CURRENT_DATE 
  AND current_capacity < max_capacity;
```

---

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- booking.test.js
```

### Writing Tests

Create test files in `tests/` directory:

```javascript
// tests/unit/booking.test.js

const bookingService = require('../../src/services/bookingService');

describe('Booking Service', () => {
  test('should calculate correct price for private booking', () => {
    const price = bookingService.calculatePrice({
      bookingType: 'private',
      courtType: 'pickleball',
      peopleCount: 12,
      slots: [{ isPeak: false }]
    });
    
    expect(price).toBe(22); // $20 base + $2 for 2 extra people
  });
});
```

### Test Coverage

Aim for:
- Unit tests: 80%+ coverage
- Integration tests: Critical paths
- E2E tests: Main user flows

---

## Deployment

### Environment Setup

**Production Environment Variables:**
```env
NODE_ENV=production
DATABASE_URL=your_production_db_url
TELEGRAM_BOT_TOKEN=your_production_bot_token
SENTRY_DSN=your_sentry_dsn
```

### Deployment Options

#### Option 1: Docker

```bash
# Build image
docker build -t courtside-booking .

# Run container
docker run -d \
  -p 3000:3000 \
  --env-file .env.production \
  --name courtside-app \
  courtside-booking
```

#### Option 2: Railway

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link project
railway link

# Deploy
railway up
```

#### Option 3: Heroku

```bash
# Install Heroku CLI
brew tap heroku/brew && brew install heroku

# Login
heroku login

# Create app
heroku create courtside-booking

# Add PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# Deploy
git push heroku main
```

### Post-Deployment

1. **Run Migrations**
   ```bash
   npm run migrate
   ```

2. **Set Telegram Webhook**
   ```bash
   curl -X POST https://api.telegram.org/bot<TOKEN>/setWebhook \
     -d url=https://your-domain.com/webhook
   ```

3. **Test Production Bot**
   - Send `/start` to bot
   - Make a test booking
   - Verify payments work

---

## Troubleshooting

### Common Issues

#### Bot Not Responding

**Check:**
1. Bot token is correct in `.env`
2. Application is running: `npm run dev`
3. Database connection is working
4. Check logs: `docker-compose logs -f app`

**Solution:**
```bash
# Restart the bot
npm run dev

# Check Telegram API
curl https://api.telegram.org/bot<TOKEN>/getMe
```

#### Database Connection Error

**Check:**
1. PostgreSQL is running: `docker-compose ps`
2. Database URL is correct in `.env`
3. Database exists: `psql -l`

**Solution:**
```bash
# Restart database
docker-compose restart postgres

# Check connection
psql $DATABASE_URL -c "SELECT 1"
```

#### Payment Not Working

**Check:**
1. Payment token is correct
2. Bot has payments enabled (@BotFather)
3. Test mode vs production mode

**Solution:**
```bash
# Verify payment setup with BotFather
# Check payment logs in application
```

### Debugging

**Enable Debug Logging:**
```env
LOG_LEVEL=debug
```

**View Logs:**
```bash
# Application logs
tail -f logs/app.log

# Docker logs
docker-compose logs -f

# Database logs
docker-compose logs postgres
```

**Database Debugging:**
```sql
-- Enable query logging
ALTER DATABASE courtside SET log_statement = 'all';

-- View slow queries
SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;
```

### Getting Help

1. Check documentation in `docs/` directory
2. Search existing issues on GitHub
3. Create a new issue with:
   - Error message
   - Steps to reproduce
   - Environment details
   - Relevant logs

---

## Best Practices

### Security

- Never commit `.env` file
- Use environment variables for secrets
- Implement rate limiting
- Validate all user input
- Use parameterized queries

### Performance

- Use database indexes
- Cache availability queries
- Implement connection pooling
- Monitor query performance
- Use async/await properly

### Code Quality

- Write descriptive commit messages
- Add comments for complex logic
- Keep functions small and focused
- Follow DRY principle
- Write tests for new features

---

## Additional Resources

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)

---

**Last Updated:** 2025-11-27
