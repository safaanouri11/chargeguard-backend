const express      = require('express');
const Notification = require('../models/Notification');
const protect      = require('../middleware/protect');
const router = express.Router();
// GET /api/notifications
router.get('/', protect, async function(req, res) {
  try {
    var limit = parseInt(req.query.limit) || 50;
    var notes = await Notification.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(limit);
    res.json(notes);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/notifications/unread-count
router.get('/unread-count', protect, async function(req, res) {
  try {
    var count = await Notification.countDocuments({ user: req.user._id, read: false });
    res.json({ count: count });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/notifications/read-all
router.put('/read-all', protect, async function(req, res) {
  try {
    await Notification.updateMany({ user: req.user._id, read: false }, { read: true });
    res.json({ message: 'All marked as read' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// PUT /api/notifications/:id/read
router.put('/:id/read', protect, async function(req, res) {
  try {
    var note = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { read: true },
      { new: true }
    );
    if (!note) return res.status(404).json({ message: 'Not found' });
    res.json(note);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// DELETE /api/notifications/:id
router.delete('/:id', protect, async function(req, res) {
  try {
    var note = await Notification.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!note) return res.status(404).json({ message: 'Not found' });
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// DELETE /api/notifications
router.delete('/', protect, async function(req, res) {
  try {
    await Notification.deleteMany({ user: req.user._id });
    res.json({ message: 'Cleared' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;
