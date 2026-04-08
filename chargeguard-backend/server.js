require('dotenv').config({ path: __dirname + '/.env' });
const express  = require('express');
const mongoose = require('mongoose');
const cors     = require('cors');
const app = express();
// ── Middleware ─────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));
// ── Routes ─────────────────────────────────────────────────
app.use('/api/auth',     require('./routes/auth'));
app.use('/api/users',    require('./routes/users'));
app.use('/api/stations', require('./routes/stations'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/payments', require('./routes/payments'));
// ── Health Check ───────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ message: ' ChargeGuard API is running!', status: 'ok' });
});
// ── Connect to MongoDB ─────────────────────────────────────
const PORT = process.env.PORT || 3000;
const URI  = process.env.MONGODB_URI || 'mongodb://localhost:27017/chargeguard';
console.log(' Connecting to MongoDB...');
mongoose.connect(URI)
  .then(() => {
    console.log(' MongoDB Connected');
    app.listen(PORT, '0.0.0.0', () => {
      console.log(` Server running on http://0.0.0.0:${PORT}`);
    });
  })
  .catch(err => {
    console.error(' MongoDB Error:', err.message);
    console.error(' Make sure MongoDB is running: mongod --dbpath ./data');
  });