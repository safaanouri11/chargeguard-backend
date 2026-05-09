const express     = require('express');
const Booking     = require('../models/Booking');
const Station     = require('../models/Station');
const User        = require('../models/User');
const Transaction = require('../models/Transaction');
const PromoCode   = require('../models/PromoCode');
const protect     = require('../middleware/protect');
const notify      = require('../utils/notify');
const { tierFor } = require('../utils/loyalty');
const { validateForUser } = require('./promos');
const router = express.Router();
const BASE_BOOKING_FEE = 5;
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
    var tier = tierFor(user.points);

    // Apply loyalty discount
    var loyaltyDiscount = Math.round(BASE_BOOKING_FEE * (tier.discountPct / 100) * 100) / 100;
    var afterLoyalty = BASE_BOOKING_FEE - loyaltyDiscount;

    // Apply promo code if provided
    var promoDiscount = 0;
    var promoApplied = null;
    if (req.body.promoCode) {
      var v = await validateForUser(req.body.promoCode, user, afterLoyalty);
      if (!v.valid) return res.status(400).json({ message: v.message });
      promoDiscount = v.discount;
      promoApplied = v.promo;
    }

    var finalAmount = Math.max(0, afterLoyalty - promoDiscount);
    if (user.balance < finalAmount) {
      return res.status(400).json({ message: 'Insufficient balance. Please top up.' });
    }

    var booking = await Booking.create({
      user: req.user._id, station: req.body.stationId,
      date: req.body.date, time: req.body.time,
      price: finalAmount,
    });
    await User.findByIdAndUpdate(req.user._id, {
      $inc: { balance: -finalAmount, points: 10 },
    });
    var label = 'Booking Fee';
    if (loyaltyDiscount > 0) label += ' (' + tier.name + ' -' + tier.discountPct + '%)';
    if (promoApplied) label += ' [' + promoApplied.code + ']';
    await Transaction.create({
      user: req.user._id, label: label, amount: -finalAmount, type: 'booking',
    });
    if (promoApplied) {
      await PromoCode.findByIdAndUpdate(promoApplied._id, {
        $inc: { usedCount: 1 },
        $addToSet: { redeemedBy: req.user._id },
      });
    }
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
    var refund = booking.price != null ? booking.price : 5;
    if (refund > 0) {
      await User.findByIdAndUpdate(req.user._id, { $inc: { balance: refund } });
      await Transaction.create({ user: req.user._id, label: 'Refund', amount: refund, type: 'refund' });
    }
    var stName = booking.station && booking.station.name ? booking.station.name : 'Station';
    await notify(req.user._id,
      'Booking Cancelled',
      'Your booking at ' + stName + ' was cancelled and ' + refund + ' NIS refunded.',
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