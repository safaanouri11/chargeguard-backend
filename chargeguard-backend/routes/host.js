const express = require('express');
const Station = require('../models/Station');
const Booking = require('../models/Booking');
const User    = require('../models/User');
const Review  = require('../models/Review');
const Payout  = require('../models/Payout');
const protect = require('../middleware/protect');
const hostApproved = require('../middleware/hostApproved');
const router = express.Router();
// Check host status (accessible even if pending/rejected)
router.get('/status', protect, async function(req, res) {
  res.json({
    status: req.user.hostStatus || 'None',
    rejectionReason: req.user.rejectionReason || '',
    role: req.user.role,
  });
});
// GET /api/host/stats
router.get('/stats', protect, hostApproved, async function(req, res) {
  try {
    var myStations  = await Station.find({ host: req.user._id });
    var stationIds  = myStations.map(function(s) { return s._id; });
    var bookings    = await Booking.find({ station: { $in: stationIds } });
    var todayStr    = new Date().toLocaleDateString();
    var todayBooks  = bookings.filter(function(b) { return b.date === todayStr; });
    var earnings    = bookings.reduce(function(s, b) { return s + (b.price || 0); }, 0);
    var reviews     = await Review.find({ host: req.user._id });
    var avgRating   = reviews.length > 0
      ? reviews.reduce(function(s, r) { return s + r.rating; }, 0) / reviews.length
      : 0;
    res.json({
      totalEarnings:  Math.round(earnings * 100) / 100,
      bookingsToday:  todayBooks.length,
      activeChargers: myStations.filter(function(s) { return s.available; }).length,
      totalStations:  myStations.length,
      totalBookings:  bookings.length,
      avgRating:      Math.round(avgRating * 10) / 10,
      totalReviews:   reviews.length,
    });
  } catch (err) {
  }
    res.status(500).json({ message: err.message });
});
// GET /api/host/stations
router.get('/stations', protect, hostApproved, async function(req, res) {
  try {
    var stations = await Station.find({ host: req.user._id });
    res.json(stations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/host/stations
router.post('/stations', protect, hostApproved, async function(req, res) {
  try {
    var station = await Station.create({
      host:      req.user._id,
      name:      req.body.name,
      location:  req.body.location,
      power:     req.body.power,
      connector: req.body.connector,
      price:     req.body.price,
      status:    req.body.status || 'Active',
      network:   req.user.businessName || 'Independent', // ﺗﻠﻘﺎﺋﻲ ﻣﻦ اﻟﮭﻮﺳﺖ
      amenities: req.body.amenities || [],
      parking:   req.body.parking   || [],
      plugCount: req.body.plugCount  || 1,
      vehicles:  req.body.vehicles  || [],
      available: req.body.status === 'Coming Soon' ? false : true,
    });
    console.log('New station added: ' + station.name + ' by ' + req.user.email);
    res.status(201).json(station);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/host/stations/:id
router.put('/stations/:id', protect, hostApproved, async function(req, res) {
  try {
    var station = await Station.findOneAndUpdate(
      { _id: req.params.id, host: req.user._id },
      { name: req.body.name, power: req.body.power, connector: req.body.connector,
        price: req.body.price, 'location.address': req.body.address },
      { new: true }
    );
    if (!station) return res.status(404).json({ message: 'Not found' });
    res.json(station);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/host/stations/:id/toggle
router.put('/stations/:id/toggle', protect, hostApproved, async function(req, res) {
  try {
    var station = await Station.findOne({ _id: req.params.id, host: req.user._id });
    if (!station) return res.status(404).json({ message: 'Not found' });
    station.available = !station.available;
    await station.save();
    res.json({ available: station.available });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/host/stations/:id/occupancy   body: { occupancy: 'free'|'busy'|'offline' }
router.put('/stations/:id/occupancy', protect, hostApproved, async function(req, res) {
  try {
    var allowed = ['free', 'busy', 'offline'];
    if (!allowed.includes(req.body.occupancy)) {
      return res.status(400).json({ message: 'occupancy must be one of: ' + allowed.join(', ') });
    }
    var station = await Station.findOneAndUpdate(
      { _id: req.params.id, host: req.user._id },
      { occupancy: req.body.occupancy, available: req.body.occupancy === 'free' },
      { new: true }
    );
    if (!station) return res.status(404).json({ message: 'Not found' });
    res.json({ occupancy: station.occupancy, available: station.available });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/host/bookings
router.get('/bookings', protect, hostApproved, async function(req, res) {
  try {
    var myStations = await Station.find({ host: req.user._id }).select('_id');
    var ids = myStations.map(function(s) { return s._id; });
    var bookings = await Booking.find({ station: { $in: ids } })
      .populate('station', 'name')
      .populate('user', 'firstName lastName')
      .sort({ createdAt: -1 }).limit(20);
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/host/analytics
router.get('/analytics', protect, hostApproved, async function(req, res) {
  try {
    var myStations = await Station.find({ host: req.user._id }).select('_id');
    var ids = myStations.map(function(s) { return s._id; });
    var bookings = await Booking.find({ station: { $in: ids } });
    var days = [];
    for (var i = 6; i >= 0; i--) {
      var d = new Date();
      d.setDate(d.getDate() - i);
      var dayStr = d.toLocaleDateString();
      var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      var label  = d.getDate() + ' ' + months[d.getMonth()];
      var dayBooks = bookings.filter(function(b) { return b.date === dayStr; });
      var earned   = dayBooks.reduce(function(s, b) { return s + (b.price || 0); }, 0);
      days.push({ label, earnings: Math.round(earned * 100) / 100, count: dayBooks.length });
    }
    res.json({ daily: days });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── Host Profile ──────────────────────────────────────────
// GET /api/host/profile
router.get('/profile', protect, hostApproved, async function(req, res) {
  try {
    var user = await User.findById(req.user._id).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/host/profile
router.put('/profile', protect, hostApproved, async function(req, res) {
  try {
    var updates = {};
    if (req.body.businessName !== undefined) updates.businessName = req.body.businessName;
    if (req.body.bio          !== undefined) updates.bio          = req.body.bio;
    if (req.body.phone        !== undefined) updates.phone        = req.body.phone;
    if (req.body.bankName     !== undefined) updates.bankName     = req.body.bankName;
    if (req.body.iban         !== undefined) updates.iban         = req.body.iban;
    if (req.body.notifBookings !== undefined) updates.notifBookings = req.body.notifBookings;
    if (req.body.notifPayouts  !== undefined) updates.notifPayouts  = req.body.notifPayouts;
    if (req.body.notifReviews  !== undefined) updates.notifReviews  = req.body.notifReviews;
    var user = await User.findByIdAndUpdate(req.user._id, updates, { new: true }).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── Payouts ───────────────────────────────────────────────
// GET /api/host/payouts
router.get('/payouts', protect, hostApproved, async function(req, res) {
  try {
    var payouts = await Payout.find({ host: req.user._id }).sort({ createdAt: -1 });
    // Calculate available balance
    var myStations = await Station.find({ host: req.user._id }).select('_id');
    var ids = myStations.map(function(s) { return s._id; });
    var bookings = await Booking.find({ station: { $in: ids } });
    var totalEarned = bookings.reduce(function(s, b) { return s + (b.price || 0); }, 0);
    var totalPaid = payouts
      .filter(function(p) { return p.status !== 'Rejected'; })
      .reduce(function(s, p) { return s + p.amount; }, 0);
    var available = Math.max(0, totalEarned - totalPaid);
    res.json({
      payouts:   payouts,
      available: Math.round(available * 100) / 100,
      totalEarned: Math.round(totalEarned * 100) / 100,
      totalPaid: Math.round(totalPaid * 100) / 100,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/host/payouts/request
router.post('/payouts/request', protect, hostApproved, async function(req, res) {
  try {
    var user = await User.findById(req.user._id);
    if (!user.iban || !user.bankName) {
      return res.status(400).json({ message: 'Please add bank information first' });
    }
    var myStations = await Station.find({ host: req.user._id }).select('_id');
    var ids = myStations.map(function(s) { return s._id; });
    var bookings = await Booking.find({ station: { $in: ids } });
    var totalEarned = bookings.reduce(function(s, b) { return s + (b.price || 0); }, 0);
    var payouts = await Payout.find({ host: req.user._id, status: { $ne: 'Rejected' } });
    var totalPaid = payouts.reduce(function(s, p) { return s + p.amount; }, 0);
    var available = totalEarned - totalPaid;
    var amount = req.body.amount;
    if (amount > available) {
      return res.status(400).json({ message: 'Amount exceeds available balance' });
    }
    var payout = await Payout.create({
      host: req.user._id,
      amount: amount,
      bankName: user.bankName,
      iban: user.iban,
      status: 'Pending',
    });
    console.log('Payout requested: ' + amount + ' NIS by ' + user.email);
    res.status(201).json(payout);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── Reviews ───────────────────────────────────────────────
// GET /api/host/reviews
router.get('/reviews', protect, hostApproved, async function(req, res) {
  try {
    var reviews = await Review.find({ host: req.user._id })
      .populate('user', 'firstName lastName avatar')
      .populate('station', 'name')
      .sort({ createdAt: -1 })
      .limit(50);
    res.json(reviews);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/host/reviews (for testing - users normally call from station page)
router.post('/reviews/:stationId', protect, hostApproved, async function(req, res) {
  try {
    var station = await Station.findById(req.params.stationId);
    if (!station) return res.status(404).json({ message: 'Station not found' });
    var review = await Review.create({
      user: req.user._id,
      station: req.params.stationId,
      host: station.host,
      rating: req.body.rating,
      comment: req.body.comment,
    });
    // Update station rating
    var reviews = await Review.find({ station: req.params.stationId });
    var avgRating = reviews.reduce(function(s, r) { return s + r.rating; }, 0) / reviews.length;
    await Station.findByIdAndUpdate(req.params.stationId, { rating: Math.round(avgRating * 10) / 10 });
    res.status(201).json(review);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;