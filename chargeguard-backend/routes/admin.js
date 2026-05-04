const express     = require('express');
const User        = require('../models/User');
const Station     = require('../models/Station');
const Booking     = require('../models/Booking');
const Transaction = require('../models/Transaction');
const Payout      = require('../models/Payout');
const Ticket      = require('../models/Ticket');
const protect     = require('../middleware/protect');
const notify      = require('../utils/notify');
const router = express.Router();
function adminOnly(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
}
// ── Analytics ─────────────────────────────────────────────
router.get('/analytics', protect, adminOnly, async function(req, res) {
  try {
    var [users, drivers, hosts, pendingHosts, stations, activeStations,
         bookings, completedBookings, transactions, payouts, pendingPayouts, tickets] =
      await Promise.all([
        User.countDocuments(),
        User.countDocuments({ role: 'driver' }),
        User.countDocuments({ role: 'host', hostStatus: 'Approved' }),
        User.countDocuments({ role: 'host', hostStatus: 'Pending' }),
        Station.countDocuments(),
        Station.countDocuments({ available: true }),
        Booking.countDocuments(),
        Booking.countDocuments({ status: 'Completed' }),
        Transaction.find(),
        Payout.find({ status: 'Paid' }),
        Payout.countDocuments({ status: 'Pending' }),
        Ticket.countDocuments({ status: 'Open' }),
      ]);
    var totalRevenue = transactions
      .filter(function(t) { return t.amount < 0; })
      .reduce(function(s, t) { return s + Math.abs(t.amount); }, 0);
    var totalPaidOut = payouts.reduce(function(s, p) { return s + p.amount; }, 0);
    // Last 7 days bookings
    var days = [];
    for (var i = 6; i >= 0; i--) {
      var d = new Date();
      d.setDate(d.getDate() - i);
      var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      var label  = d.getDate() + ' ' + months[d.getMonth()];
      var start  = new Date(d.setHours(0, 0, 0, 0));
      var end    = new Date(d.setHours(23, 59, 59, 999));
      var all    = await Booking.find({ createdAt: { $gte: start, $lte: end } });
      days.push({ label, count: all.length });
    }
    res.json({
      users:    { total: users, drivers, hosts, pendingHosts },
      stations: { total: stations, active: activeStations },
      bookings: { total: bookings, completed: completedBookings, daily: days },
      revenue:  { total: Math.round(totalRevenue * 100) / 100, paidOut: Math.round(totalPaidOut * 100) / 100 },
      pending:  { payouts: pendingPayouts, tickets: tickets },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── Host Management ───────────────────────────────────────
router.get('/hosts/pending', protect, adminOnly, async function(req, res) {
  try {
    var hosts = await User.find({ role: 'host', hostStatus: 'Pending' })
      .select('-password').sort({ createdAt: -1 });
    res.json(hosts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.get('/hosts/all', protect, adminOnly, async function(req, res) {
  try {
    var hosts = await User.find({ role: 'host' })
      .select('-password -idImage -licenseImage').sort({ createdAt: -1 });
    res.json(hosts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.get('/hosts/:id', protect, adminOnly, async function(req, res) {
  try {
    var host = await User.findById(req.params.id).select('-password');
    if (!host) return res.status(404).json({ message: 'Host not found' });
    res.json(host);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/hosts/:id/approve', protect, adminOnly, async function(req, res) {
  try {
    var host = await User.findByIdAndUpdate(req.params.id, {
      hostStatus: 'Approved', approvedAt: new Date(), rejectionReason: '',
    }, { new: true }).select('-password');
    if (!host) return res.status(404).json({ message: 'Host not found' });
    await notify(host._id,
      'Host Application Approved',
      'Welcome aboard! Your host account is now active. You can start adding stations.',
      'host', '/host');
    res.json({ message: 'Host approved', host });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/hosts/:id/reject', protect, adminOnly, async function(req, res) {
  try {
    var host = await User.findByIdAndUpdate(req.params.id, {
      hostStatus: 'Rejected',
      rejectionReason: req.body.reason || 'Application did not meet requirements',
    }, { new: true }).select('-password');
    if (!host) return res.status(404).json({ message: 'Host not found' });
    await notify(host._id,
      'Host Application Rejected',
      host.rejectionReason,
      'host', '/host/status');
    res.json({ message: 'Host rejected', host });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── User Management ───────────────────────────────────────
router.get('/users', protect, adminOnly, async function(req, res) {
  try {
    var users = await User.find({ role: { $ne: 'admin' } })
      .select('-password -idImage -licenseImage').sort({ createdAt: -1 });
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/users/:id/balance', protect, adminOnly, async function(req, res) {
  try {
    var user = await User.findByIdAndUpdate(req.params.id,
      { balance: req.body.balance }, { new: true }).select('-password');
    if (!user) return res.status(404).json({ message: 'Not found' });
    res.json({ message: 'Balance updated', user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.delete('/users/:id', protect, adminOnly, async function(req, res) {
  try {
    if (req.params.id === req.user._id.toString()) {
      return res.status(400).json({ message: 'Cannot delete yourself' });
    }
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── Station Management ────────────────────────────────────
router.get('/stations', protect, adminOnly, async function(req, res) {
  try {
    var stations = await Station.find().populate('host', 'firstName lastName email').sort({ createdAt: -1 });
    res.json(stations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/stations/:id/toggle', protect, adminOnly, async function(req, res) {
  try {
    var station = await Station.findById(req.params.id);
    if (!station) return res.status(404).json({ message: 'Not found' });
    station.available = !station.available;
    await station.save();
    res.json({ available: station.available });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.delete('/stations/:id', protect, adminOnly, async function(req, res) {
  try {
    await Station.findByIdAndDelete(req.params.id);
    res.json({ message: 'Station deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── Payout Approvals ──────────────────────────────────────
router.get('/payouts', protect, adminOnly, async function(req, res) {
  try {
    var payouts = await Payout.find()
      .populate('host', 'firstName lastName email businessName')
      .sort({ createdAt: -1 });
    res.json(payouts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/payouts/:id/approve', protect, adminOnly, async function(req, res) {
  try {
    var payout = await Payout.findByIdAndUpdate(req.params.id,
      { status: 'Paid' }, { new: true });
    if (!payout) return res.status(404).json({ message: 'Not found' });
    await notify(payout.host,
      'Payout Approved',
      payout.amount + ' NIS has been sent to your account (' + payout.bankName + ').',
      'payout', '/host/payouts');
    res.json({ message: 'Payout approved', payout });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/payouts/:id/reject', protect, adminOnly, async function(req, res) {
  try {
    var payout = await Payout.findByIdAndUpdate(req.params.id,
      { status: 'Rejected' }, { new: true });
    if (!payout) return res.status(404).json({ message: 'Not found' });
    await notify(payout.host,
      'Payout Rejected',
      'Your payout request of ' + payout.amount + ' NIS was rejected. Please contact support.',
      'payout', '/host/payouts');
    res.json({ message: 'Payout rejected', payout });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── Support Tickets ───────────────────────────────────────
router.get('/tickets', protect, adminOnly, async function(req, res) {
  try {
    var tickets = await Ticket.find()
      .populate('user', 'firstName lastName email')
      .sort({ createdAt: -1 });
    res.json(tickets);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/tickets/:id/resolve', protect, adminOnly, async function(req, res) {
  try {
    var ticket = await Ticket.findByIdAndUpdate(req.params.id,
      { status: 'Resolved' }, { new: true });
    if (!ticket) return res.status(404).json({ message: 'Not found' });
    res.json({ message: 'Ticket resolved', ticket });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;