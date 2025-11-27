# API Documentation

Complete API reference for the Courtside Court Booking System.

## Base URL

```
Development: http://localhost:3000/api
Production: https://api.courtside.com/api
```

## Authentication

All API requests require authentication via Telegram user verification.

```http
Authorization: Bearer <telegram_auth_token>
X-Telegram-User-ID: <telegram_user_id>
```

## Response Format

All responses follow this structure:

**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description"
  }
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `INVALID_REQUEST` | Malformed request |
| `UNAUTHORIZED` | Authentication failed |
| `NOT_FOUND` | Resource not found |
| `CONFLICT` | Resource conflict (e.g., double booking) |
| `PAYMENT_FAILED` | Payment processing failed |
| `VALIDATION_ERROR` | Input validation failed |
| `INTERNAL_ERROR` | Server error |

---

## Endpoints

### 1. Availability

#### GET `/availability`

Get court availability for a date range.

**Query Parameters:**
- `startDate` (required): Start date (YYYY-MM-DD)
- `endDate` (required): End date (YYYY-MM-DD)
- `courtType` (optional): 'pickleball' or 'tennis'
- `bookingType` (optional): 'private', 'openplay', 'lesson'

**Example Request:**
```http
GET /api/availability?startDate=2025-11-27&endDate=2025-12-03&courtType=pickleball
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "availability": [
      {
        "date": "2025-11-27",
        "courts": [
          {
            "courtId": 1,
            "courtName": "Pickleball Court 1",
            "courtNumber": 1,
            "bookingType": "private",
            "slots": [
              {
                "startTime": "07:00",
                "endTime": "08:00",
                "available": true,
                "isPeak": false
              },
              {
                "startTime": "08:00",
                "endTime": "09:00",
                "available": false,
                "isPeak": false
              }
            ]
          }
        ]
      }
    ]
  }
}
```

---

#### GET `/availability/openplay`

Get open play capacity for a date range.

**Query Parameters:**
- `startDate` (required): Start date (YYYY-MM-DD)
- `endDate` (required): End date (YYYY-MM-DD)
- `peopleCount` (optional): Number of people to check capacity for

**Example Request:**
```http
GET /api/availability/openplay?startDate=2025-11-27&endDate=2025-11-27&peopleCount=4
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "availability": [
      {
        "date": "2025-11-27",
        "slots": [
          {
            "startTime": "07:00",
            "endTime": "08:00",
            "availableSpots": 45,
            "hasCapacity": true,
            "isPeak": false,
            "pricePerPerson": 3.50
          },
          {
            "startTime": "17:00",
            "endTime": "18:00",
            "availableSpots": 20,
            "hasCapacity": true,
            "isPeak": true,
            "pricePerPerson": 5.00
          }
        ]
      }
    ]
  }
}
```

---

#### GET `/availability/lessons`

Get group lesson availability.

**Query Parameters:**
- `startDate` (required): Start date (YYYY-MM-DD)
- `endDate` (required): End date (YYYY-MM-DD)

**Example Response:**
```json
{
  "success": true,
  "data": {
    "lessons": [
      {
        "date": "2025-11-28",
        "dayOfWeek": "Tuesday",
        "courtName": "Tennis Court 1",
        "startTime": "17:00",
        "endTime": "18:00",
        "currentParticipants": 5,
        "maxParticipants": 8,
        "availableSpots": 3,
        "pricePerPerson": 15.00
      }
    ]
  }
}
```

---

### 2. Bookings

#### POST `/bookings`

Create a new booking.

**Request Body:**
```json
{
  "userId": 12345,
  "bookingType": "private",
  "courtType": "pickleball",
  "peopleCount": 8,
  "slots": [
    {
      "courtId": 1,
      "date": "2025-11-27",
      "startTime": "09:00",
      "endTime": "10:00"
    },
    {
      "courtId": 1,
      "date": "2025-11-27",
      "startTime": "10:00",
      "endTime": "11:00"
    }
  ]
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "booking": {
      "id": 12345,
      "bookingReference": "BK67890",
      "userId": 12345,
      "bookingType": "private",
      "courtType": "pickleball",
      "peopleCount": 8,
      "totalAmount": 40.00,
      "status": "pending",
      "paymentStatus": "pending",
      "slots": [
        {
          "courtId": 1,
          "courtName": "Pickleball Court 1",
          "date": "2025-11-27",
          "startTime": "09:00",
          "endTime": "10:00",
          "isPeak": false,
          "slotPrice": 20.00
        },
        {
          "courtId": 1,
          "courtName": "Pickleball Court 1",
          "date": "2025-11-27",
          "startTime": "10:00",
          "endTime": "11:00",
          "isPeak": false,
          "slotPrice": 20.00
        }
      ],
      "createdAt": "2025-11-27T12:00:00Z"
    }
  },
  "message": "Booking created successfully"
}
```

---

#### GET `/bookings/:id`

Get booking details by ID.

**Example Request:**
```http
GET /api/bookings/12345
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "booking": {
      "id": 12345,
      "bookingReference": "BK67890",
      "userId": 12345,
      "userName": "John Doe",
      "bookingType": "private",
      "courtType": "pickleball",
      "peopleCount": 8,
      "totalAmount": 40.00,
      "status": "confirmed",
      "paymentStatus": "paid",
      "slots": [...],
      "payment": {
        "id": 98765,
        "amount": 40.00,
        "method": "telegram_stars",
        "completedAt": "2025-11-27T12:05:00Z"
      },
      "createdAt": "2025-11-27T12:00:00Z"
    }
  }
}
```

---

#### GET `/bookings/user/:userId`

Get all bookings for a user.

**Query Parameters:**
- `status` (optional): Filter by status ('pending', 'confirmed', 'cancelled', 'completed')
- `upcoming` (optional): true/false - Filter upcoming bookings only
- `limit` (optional): Number of results (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Example Request:**
```http
GET /api/bookings/user/12345?upcoming=true&limit=10
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "bookings": [
      {
        "id": 12345,
        "bookingReference": "BK67890",
        "bookingType": "private",
        "courtType": "pickleball",
        "totalAmount": 40.00,
        "status": "confirmed",
        "slots": [
          {
            "date": "2025-11-27",
            "startTime": "09:00",
            "endTime": "10:00",
            "courtName": "Pickleball Court 1"
          }
        ],
        "createdAt": "2025-11-27T12:00:00Z"
      }
    ],
    "pagination": {
      "total": 15,
      "limit": 10,
      "offset": 0,
      "hasMore": true
    }
  }
}
```

---

#### DELETE `/bookings/:id`

Cancel a booking.

**Request Body:**
```json
{
  "reason": "Schedule conflict"
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "booking": {
      "id": 12345,
      "bookingReference": "BK67890",
      "status": "cancelled",
      "cancelledAt": "2025-11-27T13:00:00Z",
      "cancellationReason": "Schedule conflict",
      "refund": {
        "status": "pending",
        "amount": 40.00
      }
    }
  },
  "message": "Booking cancelled successfully"
}
```

---

### 3. Pricing

#### POST `/pricing/calculate`

Calculate pricing for a booking.

**Request Body:**
```json
{
  "bookingType": "private",
  "courtType": "pickleball",
  "peopleCount": 12,
  "slots": [
    {
      "date": "2025-11-27",
      "startTime": "09:00",
      "endTime": "10:00"
    },
    {
      "date": "2025-11-27",
      "startTime": "17:00",
      "endTime": "18:00"
    }
  ]
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "pricing": {
      "baseAmount": 40.00,
      "additionalPeopleCharge": 2.00,
      "peakSurcharge": 0.00,
      "totalAmount": 42.00,
      "breakdown": [
        {
          "description": "2 hours × $20/hour",
          "amount": 40.00
        },
        {
          "description": "2 additional people × $1",
          "amount": 2.00
        }
      ],
      "slots": [
        {
          "date": "2025-11-27",
          "startTime": "09:00",
          "endTime": "10:00",
          "isPeak": false,
          "price": 21.00
        },
        {
          "date": "2025-11-27",
          "startTime": "17:00",
          "endTime": "18:00",
          "isPeak": false,
          "price": 21.00
        }
      ]
    }
  }
}
```

---

### 4. Payments

#### POST `/payments/create`

Create a payment for a booking.

**Request Body:**
```json
{
  "bookingId": 12345,
  "userId": 12345,
  "amount": 42.00,
  "currency": "USD",
  "paymentMethod": "telegram_stars"
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "payment": {
      "id": 98765,
      "bookingId": 12345,
      "amount": 42.00,
      "currency": "USD",
      "status": "pending",
      "paymentMethod": "telegram_stars",
      "telegramPaymentUrl": "https://t.me/invoice/XXXXX"
    }
  }
}
```

---

#### POST `/payments/webhook`

Handle payment provider webhooks (Telegram Stars).

**Request Body:** (Varies by provider)

**Response:**
```json
{
  "success": true,
  "message": "Webhook processed"
}
```

---

#### POST `/payments/:id/refund`

Process a refund for a payment.

**Request Body:**
```json
{
  "amount": 42.00,
  "reason": "User cancellation"
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "refund": {
      "paymentId": 98765,
      "amount": 42.00,
      "status": "completed",
      "refundedAt": "2025-11-27T14:00:00Z"
    }
  },
  "message": "Refund processed successfully"
}
```

---

### 5. Courts

#### GET `/courts`

Get all courts.

**Query Parameters:**
- `courtType` (optional): Filter by court type
- `bookingType` (optional): Filter by booking type
- `isActive` (optional): Filter by active status

**Example Response:**
```json
{
  "success": true,
  "data": {
    "courts": [
      {
        "id": 1,
        "courtNumber": 1,
        "courtType": "pickleball",
        "bookingType": "private",
        "name": "Pickleball Court 1",
        "capacity": null,
        "isActive": true
      },
      {
        "id": 3,
        "courtNumber": 3,
        "courtType": "pickleball",
        "bookingType": "openplay",
        "name": "Pickleball Court 3",
        "capacity": 20,
        "isActive": true
      }
    ]
  }
}
```

---

### 6. Users

#### POST `/users`

Create or update user from Telegram data.

**Request Body:**
```json
{
  "telegramId": 12345678,
  "username": "johndoe",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890",
  "email": "john@example.com"
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "telegramId": 12345678,
      "username": "johndoe",
      "firstName": "John",
      "lastName": "Doe",
      "phoneNumber": "+1234567890",
      "email": "john@example.com",
      "totalBookings": 0,
      "totalSpent": 0.00,
      "createdAt": "2025-11-27T10:00:00Z"
    }
  }
}
```

---

#### GET `/users/:telegramId`

Get user by Telegram ID.

**Example Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "telegramId": 12345678,
      "username": "johndoe",
      "firstName": "John",
      "lastName": "Doe",
      "totalBookings": 15,
      "totalSpent": 450.00,
      "isActive": true,
      "createdAt": "2025-11-27T10:00:00Z"
    }
  }
}
```

---

### 7. Admin

#### POST `/admin/availability/override`

Create availability override (holidays, maintenance).

**Request Body:**
```json
{
  "courtId": 1,
  "date": "2025-12-25",
  "startTime": "00:00",
  "endTime": "23:59",
  "isAvailable": false,
  "reason": "Christmas Holiday"
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "override": {
      "id": 5,
      "courtId": 1,
      "date": "2025-12-25",
      "isAvailable": false,
      "reason": "Christmas Holiday"
    }
  },
  "message": "Override created successfully"
}
```

---

#### GET `/admin/reports/revenue`

Get revenue report.

**Query Parameters:**
- `startDate` (required): Start date
- `endDate` (required): End date
- `groupBy` (optional): 'day', 'week', 'month' (default: 'day')

**Example Response:**
```json
{
  "success": true,
  "data": {
    "report": {
      "totalRevenue": 5420.00,
      "totalBookings": 123,
      "breakdown": [
        {
          "date": "2025-11-27",
          "revenue": 340.00,
          "bookings": 15,
          "byType": {
            "pickleball_private": 120.00,
            "pickleball_openplay": 140.00,
            "tennis_private": 80.00
          }
        }
      ]
    }
  }
}
```

---

## Rate Limiting

- **General API**: 100 requests per minute per user
- **Availability endpoint**: 200 requests per minute (higher limit for browsing)
- **Payment endpoints**: 10 requests per minute per user

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1638360000
```

---

## Pagination

Paginated endpoints include:
- `limit`: Items per page (default: 50, max: 100)
- `offset`: Number of items to skip (default: 0)

Response includes:
```json
{
  "pagination": {
    "total": 150,
    "limit": 50,
    "offset": 0,
    "hasMore": true
  }
}
```

---

## Webhooks

### Payment Webhook

Endpoint: `POST /api/payments/webhook`

Telegram Stars sends payment notifications to this endpoint.

**Expected Headers:**
```
X-Telegram-Bot-Api-Secret-Token: <your_secret>
```

**Payload Example:**
```json
{
  "update_id": 123456,
  "message": {
    "successful_payment": {
      "currency": "XTR",
      "total_amount": 100,
      "invoice_payload": "booking_12345",
      "telegram_payment_charge_id": "charge_id_here",
      "provider_payment_charge_id": "provider_id_here"
    }
  }
}
```

---

## Testing

Use the following test credentials:

**Test Telegram User:**
```
telegram_id: 99999999
username: testuser
```

**Test Payment Card:**
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date
CVV: Any 3 digits
```

---

## SDK Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'https://api.courtside.com/api',
  headers: {
    'Authorization': `Bearer ${telegramAuthToken}`,
    'X-Telegram-User-ID': telegramUserId
  }
});

// Get availability
const getAvailability = async (startDate, endDate) => {
  const response = await api.get('/availability', {
    params: { startDate, endDate, courtType: 'pickleball' }
  });
  return response.data;
};

// Create booking
const createBooking = async (bookingData) => {
  const response = await api.post('/bookings', bookingData);
  return response.data;
};
```

### Python

```python
import requests

class CourtsideAPI:
    def __init__(self, base_url, auth_token, user_id):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {auth_token}',
            'X-Telegram-User-ID': str(user_id)
        }
    
    def get_availability(self, start_date, end_date):
        response = requests.get(
            f'{self.base_url}/availability',
            params={'startDate': start_date, 'endDate': end_date},
            headers=self.headers
        )
        return response.json()
    
    def create_booking(self, booking_data):
        response = requests.post(
            f'{self.base_url}/bookings',
            json=booking_data,
            headers=self.headers
        )
        return response.json()
```

---

**Last Updated:** 2025-11-27
