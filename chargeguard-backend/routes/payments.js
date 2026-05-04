const express     = require('express');
const User        = require('../models/User');
const Transaction = require('../models/Transaction');
const protect     = require('../middleware/protect');
const router = express.Router();
// GET /api/payments/transactions
router.get('/transactions', protect, async function(req, res) {
  try {
    var txs = await Transaction.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(20);
    res.json(txs);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/payments/topup
router.post('/topup', protect, async function(req, res) {
  try {
    var amount = req.body.amount;
    var user = await User.findByIdAndUpdate(
      req.user._id, { $inc: { balance: amount } }, { new: true }
    ).select('-password');
    await Transaction.create({ user: req.user._id, label: 'Wallet Top Up', amount, type: 'topup' });
    res.json({ balance: user.balance });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/payments/transfer
router.post('/transfer', protect, async function(req, res) {
  try {
    var { amount, typeName } = req.body;
    var user = await User.findById(req.user._id);
    if (user.balance < amount) return res.status(400).json({ message: 'Insufficient balance' });
    var updated = await User.findByIdAndUpdate(
      req.user._id, { $inc: { balance: -amount } }, { new: true }
    ).select('-password');
    await Transaction.create({ user: req.user._id, label: 'Transfer to ' + typeName, amount: -amount, type: 'transfer' });
    res.json({ balance: updated.balance });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;