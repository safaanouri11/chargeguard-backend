const express = require('express');
const Card    = require('../models/Card');
const protect = require('../middleware/protect');
const router = express.Router();
// GET /api/cards
router.get('/', protect, async function(req, res) {
  try {
    var cards = await Card.find({ user: req.user._id }).sort({ createdAt: 1 });
    res.json(cards);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/cards
router.post('/', protect, async function(req, res) {
  try {
    var count = await Card.countDocuments({ user: req.user._id });
    var card = await Card.create({
      user: req.user._id, type: req.body.type, number: req.body.number,
      holder: req.body.holder, expiry: req.body.expiry, icon: req.body.icon,
      color1: req.body.color1, color2: req.body.color2, isDefault: count === 0,
    });
    console.log('Card added:', card.number);
    res.status(201).json(card);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/cards/:id/default
router.put('/:id/default', protect, async function(req, res) {
  try {
    await Card.updateMany({ user: req.user._id }, { isDefault: false });
    await Card.findByIdAndUpdate(req.params.id, { isDefault: true });
    res.json({ message: 'Default updated' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// DELETE /api/cards/:id
router.delete('/:id', protect, async function(req, res) {
  try {
    var card = await Card.findById(req.params.id);
    if (!card) return res.status(404).json({ message: 'Not found' });
    await Card.findByIdAndDelete(req.params.id);
    if (card.isDefault) {
      var first = await Card.findOne({ user: req.user._id });
      if (first) await Card.findByIdAndUpdate(first._id, { isDefault: true });
    }
    res.json({ message: 'Card deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;