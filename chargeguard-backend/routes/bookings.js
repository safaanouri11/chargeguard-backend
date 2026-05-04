const express     = require('express');
const Booking     = require('../models/Booking');
const Station     = require('../models/Station');
const User        = require('../models/User');
const Transaction = require('../models/Transaction');
const protect     = require('../middleware/protect');
const notify      = require('../utils/notify');
const router = express.Router();
// GET /api/bookings
router.get('/', protect, async function(req, res) {
  try {
    var bookings = await Booking.find({ user: req.user._id })
      .populate('station', 'name location power price connector')
      .sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/bookings
router.post('/', protect, async function(req, res) {
  try {
    var user = await User.findById(req.user._id);
    if (user.balance < 5) {
      return res.status(400).json({ message: 'Insufficient balance. Please top up.' });
    }
    var booking = await Booking.create({
      user: req.user._id, station: req.body.stationId,
      date: req.body.date, time: req.body.time,
    });
    await User.findByIdAndUpdate(req.user._id, { $inc: { balance: -5, points: 10 } });
    await Transaction.create({ user: req.user._id, label: 'Booking Fee', amount: -5, type: 'booking' });
    var station = await Station.findById(req.body.stationId);
    var stationName = station ? station.name : 'Station';
    await notify(req.user._id,
      'Booking Confirmed',
      'Your booking at ' + stationName + ' on ' + req.body.date + ' at ' + req.body.time + ' is confirmed.',
      'booking',
      '/bookings/' + booking._id);
    if (station && station.host) {
      await notify(station.host,
        'New Booking',
        user.firstName + ' booked ' + stationName + ' on ' + req.body.date + ' at ' + req.body.time + '.',
        'booking',
        '/host/bookings');
    }
    res.status(201).json(booking);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/bookings/:id/cancel
router.put('/:id/cancel', protect, async function(req, res) {
  try {
    var booking = await Booking.findById(req.params.id).populate('station', 'name host');
    if (!booking) return res.status(404).json({ message: 'Not found' });
    booking.status = 'Cancelled';
    await booking.save();
    await User.findByIdAndUpdate(req.user._id, { $inc: { balance: 5 } });
    await Transaction.create({ user: req.user._id, label: 'Refund', amount: 5, type: 'refund' });
    var stName = booking.station && booking.station.name ? booking.station.name : 'Station';
    await notify(req.user._id,
      'Booking Cancelled',
      'Your booking at ' + stName + ' was cancelled and 5 NIS refunded.',
      'booking', '');
    if (booking.station && booking.station.host) {
      await notify(booking.station.host,
        'Booking Cancelled',
        'A booking at ' + stName + ' on ' + booking.date + ' was cancelled.',
        'booking', '/host/bookings');
    }
    res.json({ message: 'Cancelled and refunded' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;