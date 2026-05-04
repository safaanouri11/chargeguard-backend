const express = require('express');
const User    = require('../models/User');
const protect = require('../middleware/protect');
const { generateUniqueCode } = require('../utils/referralCode');
const router = express.Router();
// GET /api/referrals/me
router.get('/me', protect, async function(req, res) {
  try {
    var user = await User.findById(req.user._id).select('referralCode referralCount referralEarnings');
    // Backfill code if missing on legacy accounts
    if (!user.referralCode) {
      user.referralCode = await generateUniqueCode();
      await user.save();
    }
    var invitees = await User.find({ referredBy: req.user._id })
      .select('firstName lastName createdAt')
      .sort({ createdAt: -1 });
    res.json({
      code:      user.referralCode,
      count:     user.referralCount || invitees.length,
      earnings:  user.referralEarnings || 0,
      invitees:  invitees,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/referrals/validate/:code
router.get('/validate/:code', async function(req, res) {
  try {
    var code = (req.params.code || '').toUpperCase();
    var user = await User.findOne({ referralCode: code }).select('firstName lastName');
    if (!user) return res.status(404).json({ valid: false, message: 'Invalid code' });
    res.json({ valid: true, inviterName: user.firstName + ' ' + user.lastName });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;
