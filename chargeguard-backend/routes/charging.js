const express     = require('express');
const Station     = require('../models/Station');
const User        = require('../models/User');
const Booking     = require('../models/Booking');
const Transaction = require('../models/Transaction');
const protect     = require('../middleware/protect');
const router = express.Router();
// POST /api/charging/start
router.post('/start', protect, async function(req, res) {
  try {
    var station = await Station.findById(req.body.stationId);
    if (!station) return res.status(404).json({ message: 'Station not found' });
    if (!station.available) return res.status(400).json({ message: 'Station is busy' });
    await Station.findByIdAndUpdate(req.body.stationId, { available: false });
    var session = {
      sessionId:   req.user._id + '_' + Date.now(),
      stationId:   req.body.stationId,
      stationName: station.name,
      pricePerKwh: station.price,
      startTime:   new Date().toISOString(),
    };
    console.log('Charging started: ' + station.name);
    res.json({ success: true, session });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/charging/stop
router.post('/stop', protect, async function(req, res) {
  try {
    var { stationId, kwhCharged, duration, batteryPct } = req.body;
    var station = await Station.findById(stationId);
    if (!station) return res.status(404).json({ message: 'Station not found' });
    var cost = Math.round((kwhCharged || 0) * station.price * 100) / 100;
    await Station.findByIdAndUpdate(stationId, { available: true });
    var user = await User.findById(req.user._id);
    var newBalance = Math.max(0, user.balance - cost);
    var update = { balance: newBalance, $inc: { points: Math.floor((kwhCharged || 0) * 10) } };
    if (batteryPct != null) update.batteryPct = batteryPct;
    await User.findByIdAndUpdate(req.user._id, update);
    await Transaction.create({ user: req.user._id, label: 'Charging at ' + station.name, amount: -cost, type: 'charge' });
    await Booking.create({
      user: req.user._id, station: stationId,
      date: new Date().toLocaleDateString(), time: new Date().toLocaleTimeString(),
      status: 'Completed', price: cost,
    });
    console.log('Charging stopped: ' + (kwhCharged || 0) + ' kWh, cost: ' + cost + ' NIS');
    res.json({ success: true, kwhCharged, cost, duration, newBalance, pointsEarned: Math.floor((kwhCharged || 0) * 10) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;