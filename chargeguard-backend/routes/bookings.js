const router      = require('express').Router();
const protect     = require('../middleware/auth');
const Booking     = require('../models/Booking');
const Transaction = require('../models/Transaction');
const User        = require('../models/user');
// ── GET /api/bookings ─────────────────────────────────────
router.get('/', protect, async (req, res) => {
  try {
    const bookings = await Booking.find({ user: req.user._id })
      .populate('station', 'name location power price connector')
      .sort({ createdAt: -1 });
    res.json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── POST /api/bookings ────────────────────────────────────
router.post('/', protect, async (req, res) => {
  try {
    const { stationId, date, time, price } = req.body;
    // Check balance
    const user = await User.findById(req.user._id);
    if (user.balance < 5) {
      return res.status(400).json({ message: 'Insufficient balance. Please top up.' });
    }
    const booking = await Booking.create({
      user:    req.user._id,
      station: stationId,
      date, time, price: price || 5,
    });
    // Deduct booking fee + add points
    await User.findByIdAndUpdate(req.user._id, {
      $inc: { balance: -5, points: 10 }
    });
    // Save transaction
    await Transaction.create({
      user:   req.user._id,
      label:  'Booking Fee',
      amount: -5,
      type:   'booking',
    });
    res.status(201).json(booking);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── PUT /api/bookings/:id/cancel ──────────────────────────
router.put('/:id/cancel', protect, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    booking.status = 'Cancelled';
    await booking.save();
    // Refund
    await User.findByIdAndUpdate(req.user._id, { $inc: { balance: 5 } });
    await Transaction.create({
      user:   req.user._id,
      label:  'Refund — Booking Cancelled',
      amount: +5,
      type:   'refund',
    });
    res.json({ message: 'Booking cancelled and refunded' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;