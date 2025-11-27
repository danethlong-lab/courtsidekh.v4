const express = require('express');
const router = express.Router();
const logger = require('../config/logger');

// Health check endpoint
router.get('/status', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API info
router.get('/info', (req, res) => {
  res.status(200).json({
    name: 'Courtside Booking API',
    version: '1.0.0',
    description: 'Telegram-based court booking system'
  });
});

module.exports = router;
