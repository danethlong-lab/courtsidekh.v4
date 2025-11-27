# Courtside Court Booking System

A Telegram-based court booking system for Courtside club featuring 5 pickleball courts and 2 tennis courts. Users can book courts, make payments, and manage their bookings entirely through Telegram.

## 🎾 Features

- **Telegram Bot Interface**: Complete booking experience through Telegram
- **Multiple Court Types**:
  - Pickleball: 5 courts (2 private, 3 open play)
  - Tennis: 2 courts (private booking + group lessons)
- **Flexible Booking Options**:
  - Private court bookings
  - Open play sessions
  - Group lessons
- **Real-time Availability**: Weekly calendar view with hourly slots (7am - 10pm)
- **Dynamic Pricing**:
  - Peak/non-peak pricing for open play
  - Group size-based pricing
  - Automatic cost calculation
- **Payment Integration**: Telegram Stars payment support
- **Booking Management**: View and cancel bookings

## 📋 System Requirements

- Node.js 18+ or Python 3.9+
- PostgreSQL 14+
- Telegram Bot Token
- Payment Provider (Telegram Stars)

## 🏗️ Architecture

```
┌─────────────────┐
│  Telegram Bot   │
│   (Frontend)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   API Server    │
│  (Node/Python)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   PostgreSQL    │
│    Database     │
└─────────────────┘
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/courtside-booking.git
cd courtside-booking
```

### 2. Set Up Environment Variables

Create a `.env` file in the root directory:

```env
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_PAYMENT_PROVIDER_TOKEN=your_payment_token_here

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/courtside

# Application
PORT=3000
NODE_ENV=development

# Business Hours
OPENING_HOUR=7
CLOSING_HOUR=22

# Pricing
PICKLEBALL_PRIVATE_RATE=20
PICKLEBALL_OPENPLAY_NONPEAK_RATE=3.50
PICKLEBALL_OPENPLAY_PEAK_RATE=5.00
TENNIS_PRIVATE_BASE_RATE=24
TENNIS_PRIVATE_ADDITIONAL_RATE=12
TENNIS_LESSON_RATE=15

# Peak Hours (24-hour format)
PEAK_START_HOUR=17
PEAK_END_HOUR=21
```

### 3. Database Setup

```bash
# Create database
createdb courtside

# Run migrations
npm run migrate
# or
python manage.py migrate
```

### 4. Install Dependencies

**Node.js:**
```bash
npm install
```

**Python:**
```bash
pip install -r requirements.txt
```

### 5. Run the Application

**Development:**
```bash
npm run dev
# or
python app.py
```

**Production:**
```bash
npm start
# or
gunicorn app:app
```

## 📁 Project Structure

```
courtside-booking/
├── src/
│   ├── bot/                 # Telegram bot handlers
│   │   ├── handlers/
│   │   │   ├── start.js
│   │   │   ├── booking.js
│   │   │   ├── payment.js
│   │   │   └── mybookings.js
│   │   └── index.js
│   ├── api/                 # API endpoints
│   │   ├── routes/
│   │   │   ├── courts.js
│   │   │   ├── bookings.js
│   │   │   └── availability.js
│   │   └── index.js
│   ├── services/            # Business logic
│   │   ├── bookingService.js
│   │   ├── availabilityService.js
│   │   ├── pricingService.js
│   │   └── paymentService.js
│   ├── models/              # Database models
│   │   ├── Court.js
│   │   ├── Booking.js
│   │   ├── User.js
│   │   └── Payment.js
│   └── utils/               # Utilities
│       ├── dateHelper.js
│       └── validation.js
├── migrations/              # Database migrations
├── tests/                   # Test files
├── docs/                    # Documentation
│   ├── API.md
│   ├── DATABASE_SCHEMA.md
│   └── BOOKING_FLOW.md
├── .env.example
├── package.json
├── README.md
└── docker-compose.yml
```

## 💳 Pricing Model

### Pickleball Courts

**Private Booking (Courts 1 & 2):**
- Base: $20/hour (includes up to 10 people)
- Additional: $1 per person over 10
- No maximum capacity

**Open Play (Courts 3, 4, 5):**
- Non-peak: $3.50/person/hour (7am-5pm)
- Peak: $5.00/person/hour (5pm-9pm)
- Capacity: 20 people per court (60 total)
- No capacity limit

### Tennis Courts

**Private Booking:**
- Base: $24/hour (includes 1 person)
- Additional: $12/person/hour
- No capacity limit

**Group Lessons:**
- Rate: $15/person
- Schedule: Tuesday, Wednesday, Thursday (5pm-6pm)
- Location: Tennis Court 1
- Maximum: 8 people per class

## 🔄 Booking Flow

1. **Main Menu**
   - User starts bot with `/start`
   - Options: Book a Court, My Bookings, About

2. **Court Type Selection**
   - Choose: Pickleball Courts or Tennis Courts

3. **Booking Type Selection**
   - Pickleball: Private Court or Open Play
   - Tennis: Private Court or Group Lesson

4. **Calendar View**
   - Weekly view (7 days)
   - Hourly slots (7am-10pm)
   - Multi-slot selection across days

5. **People Count**
   - Enter number of people in group

6. **Summary & Confirmation**
   - Review booking details
   - See calculated cost

7. **Payment**
   - Telegram Stars payment
   - Processing confirmation

8. **Booking Confirmed**
   - Receive booking reference
   - Email confirmation sent

## 🗄️ Database Schema

See [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) for detailed schema documentation.

**Key Tables:**
- `users` - Telegram user information
- `courts` - Court details and types
- `bookings` - Booking records
- `payments` - Payment transactions
- `availability_overrides` - Custom availability rules

## 🔌 API Documentation

See [API.md](docs/API.md) for complete API documentation.

**Key Endpoints:**
- `GET /api/availability` - Get court availability
- `POST /api/bookings` - Create a booking
- `GET /api/bookings/:id` - Get booking details
- `DELETE /api/bookings/:id` - Cancel a booking
- `POST /api/payments` - Process payment

## 🧪 Testing

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test booking.test.js
```

## 🐳 Docker Deployment

```bash
# Build and run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📝 Environment Configuration

### Development
- Local PostgreSQL instance
- Telegram Bot Test Token
- Debug logging enabled

### Production
- Managed database (e.g., AWS RDS, Railway)
- Production bot token
- Error tracking (Sentry)
- Rate limiting enabled
- HTTPS required

## 🔒 Security Considerations

- All payment data handled through Telegram's secure payment API
- User authentication via Telegram ID
- Rate limiting on API endpoints
- Input validation and sanitization
- SQL injection prevention via parameterized queries
- CORS configuration for API
- Environment variables for sensitive data

## 🛠️ Development

### Code Style
- ESLint for JavaScript/Node.js
- Prettier for code formatting
- Pre-commit hooks with Husky

### Git Workflow
- `main` - Production branch
- `develop` - Development branch
- `feature/*` - Feature branches
- `bugfix/*` - Bug fix branches

### Making Changes
1. Create feature branch from `develop`
2. Make changes and write tests
3. Submit PR for review
4. Merge to `develop` after approval
5. Deploy to staging for testing
6. Merge to `main` for production

## 📊 Monitoring

- Application logs via Winston/Pino
- Database query performance
- Bot response times
- Payment success rates
- Error tracking with Sentry
- User analytics

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋 Support

- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/yourusername/courtside-booking/issues)
- Email: support@courtside.com

## 🗺️ Roadmap

- [ ] Mobile app (React Native)
- [ ] WhatsApp integration
- [ ] Recurring bookings
- [ ] Waitlist functionality
- [ ] Tournament management
- [ ] Member loyalty program
- [ ] Coach booking system
- [ ] Equipment rental integration
- [ ] Weather-based rescheduling
- [ ] Analytics dashboard

## 👥 Team

- **Project Lead**: Your Name
- **Developers**: Development Team
- **Designers**: Design Team

---

**Made with ❤️ for Courtside Club**
