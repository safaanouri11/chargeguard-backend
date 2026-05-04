const express  = require('express');
const Bookmark = require('../models/Bookmark');
const protect  = require('../middleware/protect');
const router = express.Router();
// GET /api/bookmarks
router.get('/', protect, async function(req, res) {
  try {
    var bookmarks = await Bookmark.find({ user: req.user._id })
      .populate('station')
      .sort({ createdAt: -1 });
    res.json(bookmarks);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/bookmarks/:stationId
router.post('/:stationId', protect, async function(req, res) {
  try {
    var existing = await Bookmark.findOne({ user: req.user._id, station: req.params.stationId });
    if (existing) return res.status(400).json({ message: 'Already bookmarked' });
    var bookmark = await Bookmark.create({ user: req.user._id, station: req.params.stationId });
    res.status(201).json(bookmark);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// DELETE /api/bookmarks/:stationId
router.delete('/:stationId', protect, async function(req, res) {
  try {
    await Bookmark.findOneAndDelete({ user: req.user._id, station: req.params.stationId });
    res.json({ message: 'Bookmark removed' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/bookmarks/ids — just IDs for fast checking
router.get('/ids', protect, async function(req, res) {
  try {
    var bookmarks = await Bookmark.find({ user: req.user._id }).select('station');
    res.json(bookmarks.map(function(b) { return b.station.toString(); }));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;