const express = require('express');
const Station = require('../models/Station');
const User    = require('../models/User');
const protect = require('../middleware/protect');
const router = express.Router();
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
module.exports = router;