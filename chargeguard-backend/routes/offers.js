const express = require('express');
const Offer   = require('../models/Offer');
const Claim   = require('../models/Claim');
const protect = require('../middleware/protect');
const router = express.Router();
// GET /api/offers
router.get('/', async function(req, res) {
  try {
    var offers = await Offer.find({ active: true }).sort({ createdAt: -1 });
    res.json(offers);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/offers/seed
router.get('/seed', async function(req, res) {
  try {
    await Offer.deleteMany({});
    await Offer.insertMany([
      { title: 'First Charge Free!',    sub: 'Get your first charging session completely free.', code: 'FIRST-FREE', discount: '100%', expires: 'Dec 31, 2026', color: 0xFF00E5A0, type: 'promo', badge: 'NEW',     active: true },
      { title: '20% Off This Weekend',  sub: 'Enjoy 20% discount on all sessions this weekend.',  code: 'CHARGE20',   discount: '20%',  expires: 'Apr 30, 2026', color: 0xFF6C63FF, type: 'promo', badge: 'LIMITED', active: true },
      { title: 'Refer & Earn',          sub: 'Invite a friend and get 5 kWh free.',               code: 'REFER-5KWH', discount: '5 kWh',expires: 'No expiry',    color: 0xFFFF6B6B, type: 'promo', badge: 'POPULAR', active: true },
      { title: 'Night Owl Special',     sub: 'Charge 10 PM to 6 AM and get 30% off.',             code: 'NIGHT30',    discount: '30%',  expires: 'Jun 30, 2026', color: 0xFF4ECDC4, type: 'flash', badge: 'ACTIVE',  active: true },
      { title: 'Happy Hour',            sub: 'All stations 40% off during happy hour.',            code: 'HAPPY40',    discount: '40%',  expires: 'Daily',        color: 0xFF00E5A0, type: 'flash', badge: 'DAILY',   active: true },
      { title: 'Flash Deal',            sub: '50% off for limited time only!',                    code: 'FLASH50',    discount: '50%',  expires: 'Limited',      color: 0xFFFF6B6B, type: 'flash', badge: 'HOT',     active: true },
    ]);
    res.json({ message: 'Offers seeded!' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/offers/my-claims
router.get('/my-claims', protect, async function(req, res) {
  try {
    var claims = await Claim.find({ user: req.user._id }).select('offer');
    res.json(claims.map(function(c) { return c.offer.toString(); }));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/offers/claim/:id
router.post('/claim/:id', protect, async function(req, res) {
  try {
    var existing = await Claim.findOne({ user: req.user._id, offer: req.params.id });
    if (existing) return res.status(400).json({ message: 'Already claimed' });
    var claim = await Claim.create({ user: req.user._id, offer: req.params.id });
    res.status(201).json({ message: 'Claimed!', claim });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;