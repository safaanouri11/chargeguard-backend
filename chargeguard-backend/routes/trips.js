const express     = require('express');
const Trip        = require('../models/Trip');
const BatteryReading = require('../models/BatteryReading');
const protect     = require('../middleware/protect');
const router = express.Router();

// GET /api/trips — list trips, newest first (paginated)
router.get('/', protect, async function(req, res) {
  try {
    var limit = Math.min(parseInt(req.query.limit) || 50, 200);
    var trips = await Trip.find({ user: req.user._id })
      .populate('station', 'name location power connector network')
      .sort({ endedAt: -1 })
      .limit(limit);
    res.json(trips);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/trips/stats — aggregated stats for the analytics screen
router.get('/stats', protect, async function(req, res) {
  try {
    var trips = await Trip.find({ user: req.user._id });
    var totalKwh      = trips.reduce(function(s, t) { return s + (t.kwhCharged   || 0); }, 0);
    var totalCost     = trips.reduce(function(s, t) { return s + (t.cost         || 0); }, 0);
    var totalDuration = trips.reduce(function(s, t) { return s + (t.durationMin  || 0); }, 0);
    var avgKwh        = trips.length ? totalKwh  / trips.length : 0;
    var avgCost       = trips.length ? totalCost / trips.length : 0;
    var avgPrice      = totalKwh ? totalCost / totalKwh : 0;
    // Last 7 days bar chart
    var days = [];
    for (var i = 6; i >= 0; i--) {
      var d = new Date();
      d.setHours(0, 0, 0, 0);
      d.setDate(d.getDate() - i);
      var end = new Date(d); end.setDate(d.getDate() + 1);
      var dayTrips = trips.filter(function(t) {
        return t.endedAt >= d && t.endedAt < end;
      });
      var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      days.push({
        label: d.getDate() + ' ' + months[d.getMonth()],
        kwh:   Math.round(dayTrips.reduce(function(s, t) { return s + (t.kwhCharged || 0); }, 0) * 10) / 10,
        cost:  Math.round(dayTrips.reduce(function(s, t) { return s + (t.cost       || 0); }, 0) * 100) / 100,
        count: dayTrips.length,
      });
    }
    res.json({
      totalTrips:    trips.length,
      totalKwh:      Math.round(totalKwh * 10) / 10,
      totalCost:     Math.round(totalCost * 100) / 100,
      totalDurationMin: totalDuration,
      avgKwh:        Math.round(avgKwh * 10) / 10,
      avgCost:       Math.round(avgCost * 100) / 100,
      avgPricePerKwh:Math.round(avgPrice * 100) / 100,
      daily:         days,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/trips/:id
router.get('/:id', protect, async function(req, res) {
  try {
    var trip = await Trip.findOne({ _id: req.params.id, user: req.user._id })
      .populate('station', 'name location power connector network price');
    if (!trip) return res.status(404).json({ message: 'Not found' });
    res.json(trip);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/users/battery-history — readings over time for the chart
router.get('/battery/history', protect, async function(req, res) {
  try {
    var limit = Math.min(parseInt(req.query.limit) || 200, 500);
    var readings = await BatteryReading.find({ user: req.user._id })
      .sort({ recordedAt: 1 })
      .limit(limit);
    res.json(readings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/users/battery-health — Tessie-style health summary
router.get('/battery/health', protect, async function(req, res) {
  try {
    var readings = await BatteryReading.find({ user: req.user._id }).sort({ recordedAt: 1 });
    var chargeReadings = readings.filter(function(r) {
      return r.source === 'charge_stop' && r.kwhDelta && r.kwhDelta > 0;
    });
    // Estimate effective full-pack capacity. Assume the typical EV uses ~0.2 kWh/km,
    // so kWh added between batteryPct deltas implies range. For simplicity here:
    // range_per_full = (kwhDelta / pctDelta * 100) / 0.2  (km)
    var lastReading = readings.length ? readings[readings.length - 1] : null;
    var maxRange = null;
    if (chargeReadings.length >= 1) {
      // Use the most recent charge to estimate
      var avgRange = 0;
      var samples = chargeReadings.slice(-10); // last 10 sessions
      samples.forEach(function(r) {
        if (r.kwhDelta && r.batteryPct > 0) {
          // kWh per percent → kWh per 100% → km at 0.2 kWh/km
          var fullKwh = r.kwhDelta * (100 / (r.batteryPct || 100));
          avgRange += fullKwh / 0.2;
        }
      });
      maxRange = samples.length ? Math.round(avgRange / samples.length) : null;
    }
    res.json({
      readingsCount: readings.length,
      chargeCycles:  chargeReadings.length,
      currentPct:    lastReading ? lastReading.batteryPct : null,
      estimatedMaxRangeKm: maxRange,
      // Time-series for the graph
      rangeSeries:   chargeReadings.map(function(r) {
        var fullKwh = r.kwhDelta * (100 / (r.batteryPct || 100));
        return {
          recordedAt: r.recordedAt,
          rangeKm:    Math.round((fullKwh / 0.2) * 10) / 10,
          kwhDelta:   r.kwhDelta,
          batteryPct: r.batteryPct,
        };
      }),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/users/battery-reading — record a manual or auto reading
router.post('/battery/reading', protect, async function(req, res) {
  try {
    var pct = Number(req.body.batteryPct);
    if (!isFinite(pct) || pct < 0 || pct > 100) {
      return res.status(400).json({ message: 'batteryPct must be 0–100' });
    }
    var reading = await BatteryReading.create({
      user:       req.user._id,
      batteryPct: pct,
      source:     req.body.source || 'manual',
      kwhDelta:   req.body.kwhDelta != null ? Number(req.body.kwhDelta) : null,
      station:    req.body.stationId || null,
    });
    res.status(201).json(reading);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
