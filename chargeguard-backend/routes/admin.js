const express     = require('express');
const bcrypt      = require('bcryptjs');
const User        = require('../models/User');
const Station     = require('../models/Station');
const Booking     = require('../models/Booking');
const Transaction = require('../models/Transaction');
const Payout      = require('../models/Payout');
const Ticket      = require('../models/Ticket');
const PromoCode   = require('../models/PromoCode');
const Notification    = require('../models/Notification');
const AuditLog        = require('../models/AuditLog');
const PlatformConfig  = require('../models/PlatformConfig');
const protect     = require('../middleware/protect');
const notify      = require('../utils/notify');
const audit       = require('../utils/audit');
const ai          = require('../utils/ai');
const router = express.Router();

function adminOnly(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
}

// requireSubRole: enforce admin sub-role on sensitive routes.
// Super admins always pass. Pass an array of allowed sub-roles.
function requireSubRole(allowed) {
  return function(req, res, next) {
    var sr = req.user.adminSubRole || 'super';
    if (sr === 'super' || allowed.indexOf(sr) !== -1) return next();
    return res.status(403).json({ message: 'Insufficient admin privileges' });
  };
}

// CSV helper — quotes values, escapes embedded quotes.
function toCsv(rows, columns) {
  function esc(v) {
    if (v === null || v === undefined) return '';
    var s = String(v).replace(/"/g, '""');
    return '"' + s + '"';
  }
  var head = columns.map(function(c) { return esc(c.label); }).join(',');
  var body = rows.map(function(r) {
    return columns.map(function(c) { return esc(typeof c.value === 'function' ? c.value(r) : r[c.value]); }).join(',');
  }).join('\n');
  return head + '\n' + body;
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

// ── Full Analytics (advanced charts) ──────────────────────
// 30-day revenue series, user growth, top stations, top hosts, connector mix.
router.get('/analytics/full', protect, adminOnly, async function(req, res) {
  try {
    var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    var revenue30 = [];
    var userGrowth30 = [];
    var bookings30 = [];

    var allUsers = await User.find().select('createdAt').lean();
    var allTx    = await Transaction.find().select('amount createdAt').lean();

    for (var i = 29; i >= 0; i--) {
      var d = new Date();
      d.setDate(d.getDate() - i);
      var label = d.getDate() + ' ' + months[d.getMonth()];
      var dayStart = new Date(d); dayStart.setHours(0, 0, 0, 0);
      var dayEnd   = new Date(d); dayEnd.setHours(23, 59, 59, 999);

      var rev = allTx
        .filter(function(t) {
          return t.amount < 0 && t.createdAt >= dayStart && t.createdAt <= dayEnd;
        })
        .reduce(function(s, t) { return s + Math.abs(t.amount); }, 0);
      revenue30.push({ label, value: Math.round(rev * 100) / 100 });

      var cumUsers = allUsers.filter(function(u) { return u.createdAt <= dayEnd; }).length;
      userGrowth30.push({ label, value: cumUsers });

      var bks = await Booking.countDocuments({
        createdAt: { $gte: dayStart, $lte: dayEnd },
      });
      bookings30.push({ label, value: bks });
    }

    // Top stations by booking count
    var topStationsAgg = await Booking.aggregate([
      { $group: { _id: '$station', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 5 },
    ]);
    var stationIds = topStationsAgg.map(function(a) { return a._id; }).filter(Boolean);
    var stationDocs = await Station.find({ _id: { $in: stationIds } })
        .select('name network location').lean();
    var topStations = topStationsAgg.map(function(a) {
      var s = stationDocs.find(function(d) { return String(d._id) === String(a._id); });
      return {
        name: s ? s.name : 'Unknown',
        network: s ? s.network : '',
        count: a.count,
      };
    });

    // Top hosts by earnings
    var topHostsDocs = await User.find({ role: 'host', hostStatus: 'Approved' })
      .sort({ hostEarnings: -1 })
      .limit(5)
      .select('firstName lastName businessName hostEarnings').lean();
    var topHosts = topHostsDocs.map(function(h) {
      return {
        name: (h.businessName && h.businessName.length)
          ? h.businessName
          : (h.firstName + ' ' + h.lastName),
        earnings: Math.round((h.hostEarnings || 0) * 100) / 100,
      };
    });

    // Connector distribution across stations
    var connectorAgg = await Station.aggregate([
      { $group: { _id: '$connector', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);
    var connectors = connectorAgg.map(function(c) {
      return { name: c._id || 'Other', count: c.count };
    });

    // Peak hours (last 30 days)
    var since = new Date(); since.setDate(since.getDate() - 30);
    var hourAgg = await Booking.aggregate([
      { $match: { createdAt: { $gte: since } } },
      { $project: { hour: { $hour: '$createdAt' } } },
      { $group: { _id: '$hour', count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);
    var peakHours = [];
    for (var h = 0; h < 24; h++) {
      var found = hourAgg.find(function(x) { return x._id === h; });
      peakHours.push({ hour: h, count: found ? found.count : 0 });
    }

    res.json({
      revenue30: revenue30,
      userGrowth30: userGrowth30,
      bookings30: bookings30,
      topStations: topStations,
      topHosts: topHosts,
      connectors: connectors,
      peakHours: peakHours,
    });
  } catch (err) {
    console.error('analytics/full failed:', err.message);
    res.status(500).json({ message: err.message });
  }
});

// ── Host Management ───────────────────────────────────────
router.get('/hosts/pending', protect, adminOnly, requireSubRole(['moderation']), async function(req, res) {
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
router.put('/hosts/:id/approve', protect, adminOnly, requireSubRole(['moderation']), async function(req, res) {
  try {
    var host = await User.findByIdAndUpdate(req.params.id, {
      hostStatus: 'Approved', approvedAt: new Date(), rejectionReason: '',
    }, { new: true }).select('-password');
    if (!host) return res.status(404).json({ message: 'Host not found' });
    await notify(host._id,
      'Host Application Approved',
      'Welcome aboard! Your host account is now active. You can start adding stations.',
      'host', '/host');
    await audit(req, {
      action: 'approve_host',
      targetType: 'user',
      targetId: String(host._id),
      detail: 'Approved host ' + host.email,
    });
    res.json({ message: 'Host approved', host });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/hosts/:id/reject', protect, adminOnly, requireSubRole(['moderation']), async function(req, res) {
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
    await audit(req, {
      action: 'reject_host',
      targetType: 'user',
      targetId: String(host._id),
      detail: 'Rejected host ' + host.email + ' — ' + host.rejectionReason,
    });
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

// GET /api/admin/users/:id — full user detail
router.get('/users/:id', protect, adminOnly, async function(req, res) {
  try {
    var user = await User.findById(req.params.id).select('-password').lean();
    if (!user) return res.status(404).json({ message: 'Not found' });
    var [bookings, tx, sessions] = await Promise.all([
      Booking.find({ user: req.params.id })
        .populate('station', 'name location')
        .sort({ createdAt: -1 }).limit(20).lean(),
      Transaction.find({ user: req.params.id })
        .sort({ createdAt: -1 }).limit(20).lean(),
      Booking.countDocuments({ user: req.params.id, status: 'Completed' }),
    ]);
    res.json({ user: user, bookings: bookings, transactions: tx, completedSessions: sessions });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/users/:id/balance', protect, adminOnly, requireSubRole(['finance', 'support']), async function(req, res) {
  try {
    var before = await User.findById(req.params.id).select('balance').lean();
    var user = await User.findByIdAndUpdate(req.params.id,
      { balance: req.body.balance }, { new: true }).select('-password');
    if (!user) return res.status(404).json({ message: 'Not found' });
    await audit(req, {
      action: 'edit_balance',
      targetType: 'user',
      targetId: String(user._id),
      detail: 'Balance ' + (before ? before.balance : '?') + ' → ' + user.balance + ' for ' + user.email,
      before: { balance: before ? before.balance : null },
      after:  { balance: user.balance },
    });
    res.json({ message: 'Balance updated', user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/admin/users/:id/suspend — toggle suspension (ban)
router.put('/users/:id/suspend', protect, adminOnly, requireSubRole(['moderation', 'support']), async function(req, res) {
  try {
    if (req.params.id === req.user._id.toString()) {
      return res.status(400).json({ message: 'Cannot suspend yourself' });
    }
    var user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'Not found' });
    var newState = !user.suspended;
    user.suspended       = newState;
    user.suspendedReason = newState ? (req.body.reason || 'Violation of terms') : '';
    user.suspendedAt     = newState ? new Date() : null;
    await user.save();
    if (newState) {
      await notify(user._id,
        'Account Suspended',
        'Your account has been suspended. Reason: ' + user.suspendedReason,
        'system', '');
    } else {
      await notify(user._id,
        'Account Restored',
        'Your account is active again. Welcome back!',
        'system', '');
    }
    await audit(req, {
      action: newState ? 'suspend_user' : 'unsuspend_user',
      targetType: 'user',
      targetId: String(user._id),
      detail: (newState ? 'Suspended ' : 'Unsuspended ') + user.email +
              (newState && user.suspendedReason ? ' — ' + user.suspendedReason : ''),
    });
    res.json({ suspended: user.suspended, reason: user.suspendedReason });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/admin/users/:id/reset-password — admin sets a new password
router.post('/users/:id/reset-password', protect, adminOnly, requireSubRole(['support']), async function(req, res) {
  try {
    var newPass = (req.body.password || '').trim();
    if (newPass.length < 6) return res.status(400).json({ message: 'Min 6 characters' });
    var user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'Not found' });
    user.password = await bcrypt.hash(newPass, 10);
    await user.save();
    await notify(user._id,
      'Password Reset by Admin',
      'Your password was reset by an administrator. Please log in with the new password.',
      'system', '');
    await audit(req, {
      action: 'reset_password',
      targetType: 'user',
      targetId: String(user._id),
      detail: 'Reset password for ' + user.email,
    });
    res.json({ message: 'Password reset' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/users/:id', protect, adminOnly, async function(req, res) {
  try {
    if (req.params.id === req.user._id.toString()) {
      return res.status(400).json({ message: 'Cannot delete yourself' });
    }
    var u = await User.findById(req.params.id).select('email firstName lastName').lean();
    await User.findByIdAndDelete(req.params.id);
    await audit(req, {
      action: 'delete_user',
      targetType: 'user',
      targetId: req.params.id,
      detail: 'Deleted user ' + (u ? u.email : '(unknown)'),
      before: u,
    });
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
    await audit(req, {
      action: 'toggle_station',
      targetType: 'station',
      targetId: String(station._id),
      detail: (station.available ? 'Enabled ' : 'Disabled ') + (station.name || ''),
    });
    res.json({ available: station.available });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.delete('/stations/:id', protect, adminOnly, async function(req, res) {
  try {
    var s = await Station.findById(req.params.id).select('name').lean();
    await Station.findByIdAndDelete(req.params.id);
    await audit(req, {
      action: 'delete_station',
      targetType: 'station',
      targetId: req.params.id,
      detail: 'Deleted station ' + (s ? s.name : ''),
    });
    res.json({ message: 'Station deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/admin/stations/:id — admin can update any station field
router.put('/stations/:id', protect, adminOnly, async function(req, res) {
  try {
    var update = {};
    var allowed = ['network', 'name', 'power', 'connector', 'price',
                   'status', 'plugCount', 'amenities', 'parking', 'vehicles'];
    allowed.forEach(function(k) {
      if (req.body[k] !== undefined) update[k] = req.body[k];
    });
    var station = await Station.findByIdAndUpdate(req.params.id, update, { new: true });
    if (!station) return res.status(404).json({ message: 'Not found' });
    await audit(req, {
      action: 'edit_station',
      targetType: 'station',
      targetId: String(station._id),
      detail: 'Edited station ' + station.name,
      after: update,
    });
    res.json(station);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Payout Approvals ──────────────────────────────────────
router.get('/payouts', protect, adminOnly, requireSubRole(['finance']), async function(req, res) {
  try {
    var payouts = await Payout.find()
      .populate('host', 'firstName lastName email businessName')
      .sort({ createdAt: -1 });
    res.json(payouts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/payouts/:id/approve', protect, adminOnly, requireSubRole(['finance']), async function(req, res) {
  try {
    var payout = await Payout.findByIdAndUpdate(req.params.id,
      { status: 'Paid' }, { new: true });
    if (!payout) return res.status(404).json({ message: 'Not found' });
    await notify(payout.host,
      'Payout Approved',
      payout.amount + ' NIS has been sent to your account (' + payout.bankName + ').',
      'payout', '/host/payouts');
    await audit(req, {
      action: 'approve_payout',
      targetType: 'payout',
      targetId: String(payout._id),
      detail: 'Approved payout ' + payout.amount + ' NIS',
    });
    res.json({ message: 'Payout approved', payout });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/payouts/:id/reject', protect, adminOnly, requireSubRole(['finance']), async function(req, res) {
  try {
    var payout = await Payout.findByIdAndUpdate(req.params.id,
      { status: 'Rejected' }, { new: true });
    if (!payout) return res.status(404).json({ message: 'Not found' });
    await notify(payout.host,
      'Payout Rejected',
      'Your payout request of ' + payout.amount + ' NIS was rejected. Please contact support.',
      'payout', '/host/payouts');
    await audit(req, {
      action: 'reject_payout',
      targetType: 'payout',
      targetId: String(payout._id),
      detail: 'Rejected payout ' + payout.amount + ' NIS',
    });
    res.json({ message: 'Payout rejected', payout });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Support Tickets ───────────────────────────────────────
router.get('/tickets', protect, adminOnly, requireSubRole(['support']), async function(req, res) {
  try {
    var tickets = await Ticket.find()
      .populate('user', 'firstName lastName email')
      .sort({ createdAt: -1 });
    res.json(tickets);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/tickets/:id/resolve', protect, adminOnly, requireSubRole(['support']), async function(req, res) {
  try {
    var ticket = await Ticket.findByIdAndUpdate(req.params.id,
      { status: 'Resolved' }, { new: true });
    if (!ticket) return res.status(404).json({ message: 'Not found' });
    await audit(req, {
      action: 'resolve_ticket',
      targetType: 'ticket',
      targetId: String(ticket._id),
      detail: 'Resolved ticket',
    });
    res.json({ message: 'Ticket resolved', ticket });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Promo Codes (admin) ───────────────────────────────────
router.get('/promos', protect, adminOnly, async function(req, res) {
  try {
    var promos = await PromoCode.find().sort({ createdAt: -1 });
    res.json(promos);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.post('/promos', protect, adminOnly, async function(req, res) {
  try {
    var promo = await PromoCode.create({
      code:        (req.body.code || '').toUpperCase().trim(),
      description: req.body.description || '',
      type:        req.body.type || 'percentage',
      value:       req.body.value,
      active:      req.body.active !== false,
      expiresAt:   req.body.expiresAt || null,
      maxUses:     req.body.maxUses || 0,
      minBookingAmount: req.body.minBookingAmount || 0,
    });
    await audit(req, {
      action: 'create_promo',
      targetType: 'promo',
      targetId: String(promo._id),
      detail: 'Created promo ' + promo.code,
    });
    res.status(201).json(promo);
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ message: 'Code already exists' });
    res.status(500).json({ message: err.message });
  }
});
router.put('/promos/:id', protect, adminOnly, async function(req, res) {
  try {
    var promo = await PromoCode.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!promo) return res.status(404).json({ message: 'Not found' });
    res.json(promo);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.delete('/promos/:id', protect, adminOnly, async function(req, res) {
  try {
    await PromoCode.findByIdAndDelete(req.params.id);
    res.json({ message: 'Promo deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Broadcast Notifications ───────────────────────────────
// POST /api/admin/broadcast { title, body, target: 'all'|'drivers'|'hosts', link? }
router.post('/broadcast', protect, adminOnly, async function(req, res) {
  try {
    var title = (req.body.title || '').trim();
    var body  = (req.body.body  || '').trim();
    var target = req.body.target || 'all';
    if (!title) return res.status(400).json({ message: 'Title required' });
    var filter = {};
    if (target === 'drivers') filter = { role: 'driver' };
    else if (target === 'hosts') filter = { role: 'host', hostStatus: 'Approved' };
    // Admins are excluded from broadcasts to avoid noise.
    filter.role = filter.role || { $ne: 'admin' };
    var users = await User.find(filter).select('_id').lean();
    var docs = users.map(function(u) {
      return {
        user: u._id,
        title: title,
        body: body,
        type: 'broadcast',
        link: req.body.link || '',
      };
    });
    if (docs.length > 0) await Notification.insertMany(docs);
    await audit(req, {
      action: 'broadcast',
      targetType: 'broadcast',
      detail: 'Sent "' + title + '" to ' + docs.length + ' ' + target,
    });
    res.json({ message: 'Broadcast sent', count: docs.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Audit Log ─────────────────────────────────────────────
router.get('/audit-logs', protect, adminOnly, async function(req, res) {
  try {
    var limit = Math.min(parseInt(req.query.limit) || 100, 500);
    var logs = await AuditLog.find().sort({ createdAt: -1 }).limit(limit).lean();
    res.json(logs);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Platform Config ───────────────────────────────────────
router.get('/config', protect, adminOnly, async function(req, res) {
  try {
    var cfg = await PlatformConfig.getConfig();
    res.json(cfg);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.put('/config', protect, adminOnly, requireSubRole([]), async function(req, res) {
  try {
    var cfg = await PlatformConfig.getConfig();
    var before = cfg.toObject();
    var allowed = ['commissionRate', 'minBookingMinutes', 'maxBookingMinutes',
                   'cancellationWindowMin', 'pointsPerKwh', 'aiFeaturesEnabled',
                   'reviewsEnabled', 'referralsEnabled', 'referralBonus',
                   'maintenanceMode', 'maintenanceMessage'];
    allowed.forEach(function(k) {
      if (req.body[k] !== undefined) cfg[k] = req.body[k];
    });
    await cfg.save();
    await audit(req, {
      action: 'update_config',
      targetType: 'config',
      detail: 'Updated platform config',
      before: before,
      after: cfg.toObject(),
    });
    res.json(cfg);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Live View (active charging sessions) ──────────────────
router.get('/live', protect, adminOnly, async function(req, res) {
  try {
    var sessions = await Booking.find({ status: { $in: ['Charging', 'Active', 'In Progress'] } })
      .populate('user', 'firstName lastName email avatar')
      .populate('station', 'name network location power')
      .sort({ createdAt: -1 }).limit(50).lean();
    var recentTx = await Transaction.find()
      .sort({ createdAt: -1 }).limit(15)
      .populate('user', 'firstName lastName').lean();
    res.json({ activeSessions: sessions, recentTransactions: recentTx });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Fraud / Suspicious Activity ───────────────────────────
router.get('/fraud/alerts', protect, adminOnly, async function(req, res) {
  try {
    var alerts = [];
    var oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

    // 1) Users with > 5 bookings in the last hour
    var rapid = await Booking.aggregate([
      { $match: { createdAt: { $gte: oneHourAgo } } },
      { $group: { _id: '$user', count: { $sum: 1 } } },
      { $match: { count: { $gt: 5 } } },
    ]);
    if (rapid.length) {
      var rapidUsers = await User.find({ _id: { $in: rapid.map(function(r) { return r._id; }) } })
        .select('email firstName lastName').lean();
      rapid.forEach(function(r) {
        var u = rapidUsers.find(function(x) { return String(x._id) === String(r._id); });
        if (u) alerts.push({
          severity: 'high',
          type: 'rapid_bookings',
          title: 'Rapid bookings',
          message: u.email + ' made ' + r.count + ' bookings in the last hour',
          userId: String(u._id),
        });
      });
    }

    // 2) Suspended users still active
    var suspended = await User.countDocuments({ suspended: true });
    if (suspended > 0) {
      alerts.push({
        severity: 'low',
        type: 'suspended_count',
        title: 'Suspended accounts',
        message: suspended + ' user account(s) currently suspended',
      });
    }

    // 3) Stations with extreme price changes (price > 5 NIS/kWh is unusual)
    var pricey = await Station.find({ price: { $gt: 5 } }).select('name price').lean();
    pricey.forEach(function(s) {
      alerts.push({
        severity: 'medium',
        type: 'price_anomaly',
        title: 'High station price',
        message: s.name + ' is at ' + s.price + ' NIS/kWh',
      });
    });

    // 4) Pending payouts older than 7 days
    var oldPending = await Payout.find({
      status: 'Pending',
      createdAt: { $lt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
    }).populate('host', 'firstName lastName email').lean();
    oldPending.forEach(function(p) {
      alerts.push({
        severity: 'medium',
        type: 'stale_payout',
        title: 'Stale payout',
        message: 'Payout of ' + p.amount + ' NIS pending > 7 days',
      });
    });

    res.json({ alerts: alerts, count: alerts.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── AI Insights (Claude-generated monthly summary) ────────
router.get('/insights', protect, adminOnly, async function(req, res) {
  try {
    var since = new Date(); since.setDate(since.getDate() - 30);
    var [bookings30, tx30, users30, newHosts30] = await Promise.all([
      Booking.countDocuments({ createdAt: { $gte: since } }),
      Transaction.find({ createdAt: { $gte: since } }).select('amount').lean(),
      User.countDocuments({ createdAt: { $gte: since } }),
      User.countDocuments({ role: 'host', hostStatus: 'Approved', approvedAt: { $gte: since } }),
    ]);
    var revenue30 = tx30
      .filter(function(t) { return t.amount < 0; })
      .reduce(function(s, t) { return s + Math.abs(t.amount); }, 0);

    var prior = new Date(); prior.setDate(prior.getDate() - 60);
    var priorBookings = await Booking.countDocuments({
      createdAt: { $gte: prior, $lt: since },
    });
    var growthPct = priorBookings > 0
      ? Math.round(((bookings30 - priorBookings) / priorBookings) * 100)
      : 0;

    // Top station
    var topAgg = await Booking.aggregate([
      { $match: { createdAt: { $gte: since } } },
      { $group: { _id: '$station', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    var topName = '';
    if (topAgg.length) {
      var top = await Station.findById(topAgg[0]._id).select('name').lean();
      if (top) topName = top.name;
    }

    // Peak hour
    var hourAgg = await Booking.aggregate([
      { $match: { createdAt: { $gte: since } } },
      { $project: { hour: { $hour: '$createdAt' } } },
      { $group: { _id: '$hour', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    var peakHour = hourAgg.length ? hourAgg[0]._id : null;

    var stats = {
      bookings30:     bookings30,
      revenue30:      Math.round(revenue30 * 100) / 100,
      newUsers30:     users30,
      newHosts30:     newHosts30,
      bookingsGrowthPct: growthPct,
      topStation:     topName,
      peakHour:       peakHour,
    };

    // Try Claude — fall back to a deterministic message if AI unavailable.
    var summary = null;
    if (ai.isEnabled()) {
      try {
        var Anthropic = require('@anthropic-ai/sdk');
        var c = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
        var resp = await c.messages.create({
          model: process.env.ANTHROPIC_MODEL || 'claude-haiku-4-5',
          max_tokens: 300,
          system: 'You are an analyst for ChargeGuard, an EV charging platform in Palestine. ' +
                  'Given monthly metrics, write a SHORT (3 short bullet points, max 280 chars total) ' +
                  'plain-English insight summary with one actionable recommendation. No emojis. No greeting.',
          messages: [{
            role: 'user',
            content: 'Last 30 days metrics:\n' + JSON.stringify(stats, null, 2),
          }],
        });
        var b = resp.content && resp.content.find(function(x) { return x.type === 'text'; });
        summary = b ? b.text.trim() : null;
      } catch (e) {
        console.error('AI insights failed:', e.message);
      }
    }
    if (!summary) {
      var growthText = growthPct >= 0 ? 'up ' + growthPct + '%' : 'down ' + Math.abs(growthPct) + '%';
      summary =
        '• Bookings ' + growthText + ' vs prior 30 days (' + bookings30 + ' total).\n' +
        '• Revenue: ' + Math.round(revenue30) + ' NIS · ' + users30 + ' new users · ' + newHosts30 + ' new hosts.\n' +
        (topName ? '• Top station: ' + topName + '. ' : '') +
        (peakHour !== null ? 'Peak hour: ' + peakHour + ':00.' : '');
    }
    res.json({ stats: stats, summary: summary, aiUsed: ai.isEnabled() });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── Pending Counts (for dashboard bell badge) ─────────────
router.get('/pending-counts', protect, adminOnly, async function(req, res) {
  try {
    var [hosts, payouts, tickets, fraudResp] = await Promise.all([
      User.countDocuments({ role: 'host', hostStatus: 'Pending' }),
      Payout.countDocuments({ status: 'Pending' }),
      Ticket.countDocuments({ status: 'Open' }),
      Promise.resolve(0), // fraud count is derived elsewhere, keep cheap
    ]);
    res.json({
      hosts: hosts, payouts: payouts, tickets: tickets,
      total: hosts + payouts + tickets,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ── CSV Export ────────────────────────────────────────────
// GET /api/admin/export/:type — users | bookings | stations | payouts
router.get('/export/:type', protect, adminOnly, async function(req, res) {
  try {
    var type = req.params.type;
    var csv = '';
    if (type === 'users') {
      var users = await User.find({ role: { $ne: 'admin' } })
        .select('firstName lastName email phone role balance points hostStatus suspended createdAt')
        .lean();
      csv = toCsv(users, [
        { label: 'First Name',  value: 'firstName' },
        { label: 'Last Name',   value: 'lastName' },
        { label: 'Email',       value: 'email' },
        { label: 'Phone',       value: 'phone' },
        { label: 'Role',        value: 'role' },
        { label: 'Balance NIS', value: 'balance' },
        { label: 'Points',      value: 'points' },
        { label: 'Host Status', value: 'hostStatus' },
        { label: 'Suspended',   value: function(u) { return u.suspended ? 'Yes' : 'No'; } },
        { label: 'Joined',      value: function(u) { return u.createdAt; } },
      ]);
    } else if (type === 'bookings') {
      var bookings = await Booking.find()
        .populate('user', 'firstName lastName email')
        .populate('station', 'name')
        .lean();
      csv = toCsv(bookings, [
        { label: 'Booking ID', value: '_id' },
        { label: 'User',       value: function(b) { return b.user ? (b.user.firstName + ' ' + b.user.lastName) : ''; } },
        { label: 'Email',      value: function(b) { return b.user ? b.user.email : ''; } },
        { label: 'Station',    value: function(b) { return b.station ? b.station.name : ''; } },
        { label: 'Status',     value: 'status' },
        { label: 'Amount',     value: 'totalCost' },
        { label: 'kWh',        value: 'kwhUsed' },
        { label: 'Created',    value: 'createdAt' },
      ]);
    } else if (type === 'stations') {
      var stations = await Station.find().populate('host', 'firstName lastName email').lean();
      csv = toCsv(stations, [
        { label: 'Name',      value: 'name' },
        { label: 'Network',   value: 'network' },
        { label: 'Connector', value: 'connector' },
        { label: 'Power',     value: 'power' },
        { label: 'Price',     value: 'price' },
        { label: 'Available', value: function(s) { return s.available ? 'Yes' : 'No'; } },
        { label: 'Host',      value: function(s) { return s.host ? (s.host.firstName + ' ' + s.host.lastName) : ''; } },
        { label: 'Address',   value: function(s) { return s.location && s.location.address ? s.location.address : ''; } },
      ]);
    } else if (type === 'payouts') {
      var payouts = await Payout.find().populate('host', 'firstName lastName email businessName').lean();
      csv = toCsv(payouts, [
        { label: 'Host',     value: function(p) { return p.host ? (p.host.businessName || (p.host.firstName + ' ' + p.host.lastName)) : ''; } },
        { label: 'Email',    value: function(p) { return p.host ? p.host.email : ''; } },
        { label: 'Amount',   value: 'amount' },
        { label: 'Bank',     value: 'bankName' },
        { label: 'IBAN',     value: 'iban' },
        { label: 'Status',   value: 'status' },
        { label: 'Created',  value: 'createdAt' },
      ]);
    } else {
      return res.status(400).json({ message: 'Unsupported export type' });
    }
    await audit(req, {
      action: 'export',
      targetType: type,
      detail: 'Exported ' + type + ' to CSV',
    });
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="chargeguard-' + type + '.csv"');
    res.send(csv);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
