const express = require('express');
const bcrypt  = require('bcryptjs');
const User    = require('../models/User');
const Booking = require('../models/Booking');
const Transaction = require('../models/Transaction');
const protect = require('../middleware/protect');
const { loyaltyState } = require('../utils/loyalty');
const router = express.Router();
// GET /api/users/profile
router.get('/profile', protect, async function(req, res) {
  try {
    var user = await User.findById(req.user._id).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/users/profile
router.put('/profile', protect, async function(req, res) {
  try {
    var user = await User.findByIdAndUpdate(req.user._id, req.body, { new: true }).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/users/change-password
router.put('/change-password', protect, async function(req, res) {
  try {
    var { oldPassword, newPassword } = req.body;
    console.log('Change password request for:', req.user.email);
    console.log('Old pass provided:', !!oldPassword, 'New pass provided:', !!newPassword);
    if (!oldPassword || !newPassword) {
      return res.status(400).json({ message: 'Please provide old and new password' });
    }
    // Get user WITH password explicitly
    var user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    console.log('User found, has password:', !!user.password);
    var match = await bcrypt.compare(oldPassword, user.password);
    console.log('Password match:', match);
    if (!match) return res.status(400).json({ message: 'Current password is incorrect' });
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }
    var hashed = await bcrypt.hash(newPassword, 10);
    var updated = await User.findByIdAndUpdate(
      req.user._id,
      { $set: { password: hashed } },
      { new: true }
    );
    console.log('Password updated for:', updated.email);
    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    console.error('Change password error:', err.message);
    res.status(500).json({ message: err.message });
  }
});
// DELETE /api/users/delete
router.delete('/delete', protect, async function(req, res) {
  try {
    await User.findByIdAndDelete(req.user._id);
    res.json({ message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/users/battery
router.put('/battery', protect, async function(req, res) {
  try {
    var user = await User.findByIdAndUpdate(
      req.user._id, { batteryPct: req.body.batteryPct }, { new: true }
    ).select('-password');
    res.json({ batteryPct: user.batteryPct });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/users/avatar
router.post('/avatar', protect, async function(req, res) {
  try {
    var base64 = req.body.avatar;
    if (!base64) return res.status(400).json({ message: 'No image provided' });
    var user = await User.findByIdAndUpdate(
      req.user._id, { avatar: base64 }, { new: true }
    ).select('-password');
    console.log('Avatar updated for: ' + user.email);
    res.json({ avatar: user.avatar });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/users/stats
router.get('/stats', protect, async function(req, res) {
  try {
    var sessions = await Booking.countDocuments({ user: req.user._id, status: 'Completed' });
    var chargeTxs = await Transaction.find({ user: req.user._id, type: 'charge' });
    var totalSpent = chargeTxs.reduce(function(s, t) { return s + Math.abs(t.amount); }, 0);
    var totalKwh = Math.round(totalSpent / 2.5 * 10) / 10;
    var user = await User.findById(req.user._id).select('points');
    res.json({ sessions, totalKwh, points: user.points });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/users/loyalty
router.get('/loyalty', protect, async function(req, res) {
  try {
    var user = await User.findById(req.user._id).select('points');
    res.json(loyaltyState(user.points));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/users/co2
// CO2 saved by charging EV instead of driving an ICE car of the same range.
// Assumptions: 1 kWh ~ 5 km of EV range, 0.192 kg CO2 per km from a typical
// gasoline car, EV grid emissions ~0.05 kg CO2 per km in the region. Net
// savings ~0.142 kg CO2 per km, or ~0.71 kg CO2 per kWh charged.
router.get('/co2', protect, async function(req, res) {
  try {
    var chargeTxs = await Transaction.find({ user: req.user._id, type: 'charge' });
    var totalSpent = chargeTxs.reduce(function(s, t) { return s + Math.abs(t.amount); }, 0);
    var totalKwh   = totalSpent / 2.5;
    var kmDriven   = totalKwh * 5;
    var co2Saved   = totalKwh * 0.71;       // kg
    var trees      = co2Saved / 21;         // 1 tree absorbs ~21 kg CO2/year
    var litersGas  = kmDriven / 12;         // 12 km per liter typical
    res.json({
      totalKwh:        Math.round(totalKwh * 10) / 10,
      kmDriven:        Math.round(kmDriven * 10) / 10,
      co2KgSaved:      Math.round(co2Saved * 10) / 10,
      treesEquivalent: Math.round(trees * 10) / 10,
      litersGasSaved:  Math.round(litersGas * 10) / 10,
      sessions:        chargeTxs.length,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;