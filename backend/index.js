const express = require('express');
const cors = require('cors');
const app = express();
require('dotenv').config();
// ─────────────────────────────────────────────
//  CORS Configuaration
// ─────────────────────────────────────────────
app.use(cors({
  origin: '*', // Ou utilisez: 'http://localhost:58296' pour être plus strict
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ─────────────────────────────────────────────
//  Middleware
// ─────────────────────────────────────────────
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ─────────────────────────────────────────────
//  Routes
// ─────────────────────────────────────────────
app.use('/api/auth',          require('./routes/anas/auth'));
app.use('/api/clients',       require('./routes/anas/client'));
app.use('/api/coaches',       require('./routes/anas/coach'));
app.use('/api/advisors',      require('./routes/anas/advisorProfiles'));
app.use('/api/reservations',  require('./routes/anas/reservations'));
app.use('/api/availability',  require('./routes/anas/coachAvailability'));
app.use('/api/conversations', require('./routes/anas/conversations'));
app.use('/api/messages',      require('./routes/anas/messages'));
app.use('/api/invitations',   require('./routes/anas/invitations'));
app.use('/api/coach-clients', require('./routes/anas/coachClients'));
app.use('/api/bans',          require('./routes/anas/bans'));
app.use('/api/reviews',       require('./routes/anas/reviews'));
app.use('/api/weight-history', require('./routes/anas/weightHistory'));
app.use('/api/upload',        require('./routes/anas/upload'));
// ─────────────────────────────────────────────
//  Start Server
// ─────────────────────────────────────────────
app.listen(3000, () => console.log('✅ Fitlek API running on port 3000'));

module.exports = app;