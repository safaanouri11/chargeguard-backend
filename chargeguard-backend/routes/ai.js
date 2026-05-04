const express = require('express');
const Anthropic = require('@anthropic-ai/sdk');
const Station = require('../models/Station');
const User    = require('../models/User');
const protect = require('../middleware/protect');
const { distanceKm } = require('../utils/distance');
const router = express.Router();
var anthropic = null;
if (process.env.ANTHROPIC_API_KEY) {
  try { anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY }); }
  catch (e) { console.error('Anthropic init failed:', e.message); }
}
// GET /api/ai/recommend
router.get('/recommend', protect, async function(req, res) {
  try {
    var user     = await User.findById(req.user._id);
    var stations = await Station.find({ available: true });
    if (stations.length === 0) {
      return res.json({ recommendation: null, message: 'No available stations' });
    }
    var scored = stations.map(function(s) {
      var score = 0;
      if (s.connector === user.connector) score += 40;
      if (s.available) score += 20;
      score += Math.max(0, 20 - (s.price * 4));
      var pw = parseInt(s.power) || 0;
      if (pw >= 50) score += 15;
      else if (pw >= 22) score += 8;
      score += (s.rating || 5) * 2;
      return { station: s, score };
    });
    scored.sort(function(a, b) { return b.score - a.score; });
    var best = scored[0].station;
    var reasons = [];
    if (best.connector === user.connector) reasons.push('matches your ' + user.connector + ' connector');
    if (best.available) reasons.push('available now');
    if (parseInt(best.power) >= 50) reasons.push('fast charging 50 kW');
    reasons.push('great price ' + best.price + ' NIS/kWh');
    var reasonText = 'Best match: ' + reasons.slice(0, 2).join(' & ');
    console.log('AI recommended: ' + best.name);
    res.json({
      recommendation: {
        _id: best._id, name: best.name, power: best.power,
        connector: best.connector, price: best.price, available: best.available,
        location: best.location, rating: best.rating, score: scored[0].score, reason: reasonText,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/ai/route
// body: { startLat, startLng, endLat, endLng, vehicleRangeKm?, currentBatteryPct?, connector? }
router.post('/route', protect, async function(req, res) {
  try {
    var { startLat, startLng, endLat, endLng } = req.body;
    if ([startLat, startLng, endLat, endLng].some(function(v) { return typeof v !== 'number'; })) {
      return res.status(400).json({ message: 'startLat, startLng, endLat, endLng (numbers) are required' });
    }
    var user = await User.findById(req.user._id);
    var rangeKm   = req.body.vehicleRangeKm    || 300;
    var batteryPct = req.body.currentBatteryPct != null ? req.body.currentBatteryPct : (user.batteryPct || 65);
    var connector = req.body.connector || user.connector;
    var reserveBuffer = 0.15; // keep 15% reserve before next stop
    var totalDistance = distanceKm(startLat, startLng, endLat, endLng);
    var directRange = rangeKm * (batteryPct / 100);
    // Find candidate stations along the corridor
    var corridorKm = Math.max(15, totalDistance * 0.15);
    var query = {
      occupancy: { $ne: 'offline' },
      'location.lat': { $ne: null },
      'location.lng': { $ne: null },
    };
    if (connector) query.connector = connector;
    var stations = await Station.find(query);
    var candidates = stations
      .map(function(s) {
        var dStart = distanceKm(startLat, startLng, s.location.lat, s.location.lng);
        var dEnd   = distanceKm(s.location.lat, s.location.lng, endLat, endLng);
        var detour = dStart + dEnd - totalDistance;
        return { s: s, dStart: dStart, dEnd: dEnd, detour: detour };
      })
      .filter(function(c) { return c.detour <= corridorKm * 2; })
      .sort(function(a, b) { return a.dStart - b.dStart; });
    // Greedy stop selection
    var stops = [];
    var cursorRange = directRange;
    var cursorAdvance = 0; // km traveled along route
    var lastIdx = -1;
    while (cursorAdvance + cursorRange * (1 - reserveBuffer) < totalDistance) {
      // find the farthest reachable station ahead of cursor that we haven't picked
      var pick = null;
      for (var i = lastIdx + 1; i < candidates.length; i++) {
        var c = candidates[i];
        var advance = c.dStart;
        if (advance <= cursorAdvance) continue;
        var legKm = advance - cursorAdvance;
        if (legKm > cursorRange * (1 - reserveBuffer)) break;
        pick = { idx: i, c: c, legKm: legKm };
      }
      if (!pick) {
        // No reachable station — bail
        break;
      }
      var arrivalPct = Math.max(0, batteryPct - (pick.legKm / rangeKm) * 100);
      var chargeToPct = 80;
      var kwhPerPct = (rangeKm * 0.2) / 100; // rough: 0.2 kWh per km, scaled
      var kwhNeeded = (chargeToPct - arrivalPct) * kwhPerPct;
      var stationPower = parseInt(pick.c.s.power) || 22;
      var minutes = Math.round((kwhNeeded / stationPower) * 60);
      var stopCost = Math.round(kwhNeeded * (pick.c.s.price || 0) * 100) / 100;
      stops.push({
        stationId:    pick.c.s._id,
        name:         pick.c.s.name,
        address:      pick.c.s.location && pick.c.s.location.address,
        lat:          pick.c.s.location && pick.c.s.location.lat,
        lng:          pick.c.s.location && pick.c.s.location.lng,
        power:        pick.c.s.power,
        connector:    pick.c.s.connector,
        price:        pick.c.s.price,
        occupancy:    pick.c.s.occupancy,
        legKm:        Math.round(pick.legKm * 10) / 10,
        arrivalBatteryPct: Math.round(arrivalPct),
        chargeToPct:  chargeToPct,
        kwhCharged:   Math.round(kwhNeeded * 10) / 10,
        estimatedChargeMinutes: minutes,
        estimatedCost: stopCost,
      });
      cursorAdvance = pick.c.dStart;
      batteryPct = chargeToPct;
      cursorRange = rangeKm * (batteryPct / 100);
      lastIdx = pick.idx;
    }
    var feasible = (cursorAdvance + cursorRange * (1 - reserveBuffer)) >= totalDistance;
    // Final leg from last cursor to destination
    var finalLegKm = Math.max(0, totalDistance - cursorAdvance);
    var finalArrivalPct = Math.max(0, batteryPct - (finalLegKm / rangeKm) * 100);
    // Aggregates
    var avgSpeedKph = 70;
    var drivingMin = Math.round((totalDistance / avgSpeedKph) * 60);
    var totalChargingMin = stops.reduce(function(s, x) { return s + x.estimatedChargeMinutes; }, 0);
    var totalCost = Math.round(stops.reduce(function(s, x) { return s + (x.estimatedCost || 0); }, 0) * 100) / 100;
    var totalKwh  = Math.round(stops.reduce(function(s, x) { return s + (x.kwhCharged || 0); }, 0) * 10) / 10;
    // Build a summary (Anthropic if available, deterministic fallback otherwise)
    var summary = '';
    var fallback =
      'Trip ' + Math.round(totalDistance) + ' km. ' +
      (stops.length === 0
        ? 'No charging needed — current charge is sufficient.'
        : stops.length + ' stop' + (stops.length === 1 ? '' : 's') + ' recommended: ' +
          stops.map(function(x) { return x.name; }).join(', ') + '.') +
      (feasible ? '' : ' Warning: route may not be feasible with available stations.');
    if (anthropic) {
      try {
        var msg = await anthropic.messages.create({
          model: 'claude-haiku-4-5-20251001',
          max_tokens: 200,
          messages: [{
            role: 'user',
            content: 'Briefly (max 2 sentences) summarize this EV trip plan for the driver. ' +
              'Total distance ' + Math.round(totalDistance) + ' km. ' +
              'Starting battery ' + Math.round(req.body.currentBatteryPct != null ? req.body.currentBatteryPct : (user.batteryPct || 65)) + '%. ' +
              'Stops: ' + JSON.stringify(stops.map(function(x) {
                return { name: x.name, legKm: x.legKm, chargeMin: x.estimatedChargeMinutes };
              })) + '. Feasible: ' + feasible + '.',
          }],
        });
        var block = msg.content && msg.content.find(function(b) { return b.type === 'text'; });
        summary = block ? block.text.trim() : fallback;
      } catch (e) {
        console.error('Anthropic call failed:', e.message);
        summary = fallback;
      }
    } else {
      summary = fallback;
    }
    res.json({
      totalDistanceKm:  Math.round(totalDistance * 10) / 10,
      directRangeKm:    Math.round(directRange * 10) / 10,
      finalLegKm:       Math.round(finalLegKm * 10) / 10,
      finalArrivalPct:  Math.round(finalArrivalPct),
      drivingMinutes:   drivingMin,
      chargingMinutes:  totalChargingMin,
      totalMinutes:     drivingMin + totalChargingMin,
      totalCost:        totalCost,
      totalKwh:         totalKwh,
      stopCount:        stops.length,
      feasible:         feasible,
      stops:            stops,
      summary:          summary,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;