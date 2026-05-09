require('dotenv').config({ path: __dirname + '/.env' });
const express  = require('express');
const mongoose = require('mongoose');
const cors     = require('cors');
const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
// ── Routes ────────────────────────────────────────────────
app.use('/api/auth',     require('./routes/auth'));
app.use('/api/users',    require('./routes/users'));
app.use('/api/stations', require('./routes/stations'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api/cards',    require('./routes/cards'));
app.use('/api/charging', require('./routes/charging'));
app.use('/api/support',  require('./routes/support'));
app.use('/api/offers',   require('./routes/offers'));
app.use('/api/bookmarks', require('./routes/bookmarks'));
app.use('/api/host',     require('./routes/host'));
app.use('/api/admin',    require('./routes/admin'));
app.use('/api/ai',       require('./routes/ai'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/reviews',  require('./routes/reviews'));
app.use('/api/referrals', require('./routes/referrals'));
app.use('/api/promos',   require('./routes/promos'));
// ── Health Check ──────────────────────────────────────────
app.get('/', function(req, res) {
  res.json({ message: 'ChargeGuard API is running!', status: 'ok' });
});
// ── Start Server ──────────────────────────────────────────
var PORT = process.env.PORT || 3000;
var URI  = process.env.MONGODB_URI || 'mongodb://localhost:27017/chargeguard';
console.log('Connecting to MongoDB...');
mongoose.connect(URI)
  .then(function() {
    console.log('MongoDB Connected');
    app.listen(PORT, function() {
      console.log('Server running on http://localhost:' + PORT);
    });
  })
  .catch(function(err) {
    console.error('MongoDB Error:', err.message);
  });