const router      = require('express').Router();
const protect     = require('../middleware/auth');
const User        = require('../models/user');
const Transaction = require('../models/Transaction');
// ── GET /api/payments/transactions ───────────────────────
router.get('/transactions', protect, async (req, res) => {
  try {
    const txs = await Transaction.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(20);
    res.json(txs);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── POST /api/payments/topup ──────────────────────────────
router.post('/topup', protect, async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid amount' });
    }
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $inc: { balance: amount } },
      { new: true }
    ).select('-password');
    await Transaction.create({
      user:   req.user._id,
      label:  'Wallet Top Up',
      amount: +amount,
      type:   'topup',
    });
    res.json({ balance: user.balance, message: `NIS ${amount} added to wallet` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// ── POST /api/payments/transfer ───────────────────────────
router.post('/transfer', protect, async (req, res) => {
  try {
    const { amount, destination, typeName } = req.body;
    const user = await User.findById(req.user._id);
    if (user.balance < amount) {
      return res.status(400).json({ message: 'Insufficient balance' });
    }
    const updated = await User.findByIdAndUpdate(
      req.user._id,
      { $inc: { balance: -amount } },
      { new: true }
    ).select('-password');
    await Transaction.create({
      user:   req.user._id,
      label:  `Transfer → ${typeName}`,
      amount: -amount,
      type:   'transfer',
    });
    res.json({ balance: updated.balance, message: `NIS ${amount} transferred` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;