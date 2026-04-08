const router  = require('express').Router();
const protect = require('../middleware/auth');
const User    = require('../models/user');
// ── GET /api/users/profile ────────────────────────────────
router.get('/profile', protect, async (req, res) => {
  res.json(req.user);
});
// ── PUT /api/users/profile ────────────────────────────────
router.put('/profile', protect, async (req, res) => {
  try {
    const { firstName, lastName, phone, vehicle, connector, avatar, region } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { firstName, lastName, phone, vehicle, connector, avatar, region },
      { new: true }
    ).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── PUT /api/users/change-password ────────────────────────
router.put('/change-password', protect, async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findById(req.user._id);
    const match = await user.matchPassword(oldPassword);
    if (!match) return res.status(400).json({ message: 'Current password is incorrect' });
    user.password = newPassword;
    await user.save();
    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── DELETE /api/users/delete ──────────────────────────────
router.delete('/delete', protect, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user._id);
    res.json({ message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;