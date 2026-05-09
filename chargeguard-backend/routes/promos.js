const express   = require('express');
const PromoCode = require('../models/PromoCode');
const protect   = require('../middleware/protect');
const router = express.Router();

// Compute the discount this code would apply to `amount`. Does NOT mutate
// the promo. Used by validate + booking flows.
function computeDiscount(promo, amount) {
  if (promo.type === 'percentage') {
    return Math.round(amount * (promo.value / 100) * 100) / 100;
  }
  return Math.min(amount, promo.value);
}

// Validate a promo for a given user + amount. Returns
// { valid, discount, finalAmount, message } and the promo doc if valid.
async function validateForUser(code, user, amount) {
  if (!code) return { valid: false, message: 'Code required' };
  var promo = await PromoCode.findOne({ code: (code || '').toUpperCase().trim() });
  if (!promo) return { valid: false, message: 'Invalid code' };
  if (!promo.active) return { valid: false, message: 'Code is no longer active' };
  if (promo.expiresAt && new Date() > promo.expiresAt) {
    return { valid: false, message: 'Code has expired' };
  }
  if (promo.maxUses > 0 && promo.usedCount >= promo.maxUses) {
    return { valid: false, message: 'Code has reached its usage limit' };
  }
  if (amount < (promo.minBookingAmount || 0)) {
    return { valid: false,
      message: 'Minimum booking ' + promo.minBookingAmount + ' NIS required' };
  }
  if (user && promo.redeemedBy.some(function(uid) { return uid.equals(user._id); })) {
    return { valid: false, message: 'You have already used this code' };
  }
  var discount = computeDiscount(promo, amount);
  return {
    valid: true,
    promo: promo,
    discount: discount,
    finalAmount: Math.max(0, amount - discount),
    message: 'Code applied — saved ' + discount + ' NIS',
  };
}

// POST /api/promos/validate { code, amount }
router.post('/validate', protect, async function(req, res) {
  try {
    var amount = req.body.amount != null ? req.body.amount : 5;
    var result = await validateForUser(req.body.code, req.user, amount);
    if (!result.valid) return res.status(400).json(result);
    // Strip promo doc from response — keep it minimal
    res.json({
      valid: true,
      code: result.promo.code,
      type: result.promo.type,
      value: result.promo.value,
      description: result.promo.description,
      discount: result.discount,
      finalAmount: result.finalAmount,
      message: result.message,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/promos/list — show currently usable codes (excluding redeemed)
router.get('/list', protect, async function(req, res) {
  try {
    var promos = await PromoCode.find({
      active: true,
      $or: [{ expiresAt: null }, { expiresAt: { $gt: new Date() } }],
      redeemedBy: { $ne: req.user._id },
    }).sort({ createdAt: -1 }).limit(20);
    res.json(promos.map(function(p) {
      return {
        code: p.code, description: p.description,
        type: p.type, value: p.value,
        expiresAt: p.expiresAt, minBookingAmount: p.minBookingAmount,
      };
    }));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
module.exports.validateForUser = validateForUser;
module.exports.computeDiscount = computeDiscount;
