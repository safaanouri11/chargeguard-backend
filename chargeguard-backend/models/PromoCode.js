const mongoose = require('mongoose');
const promoSchema = new mongoose.Schema({
  code:        { type: String, required: true, unique: true, uppercase: true, trim: true },
  description: { type: String, default: '' },
  type:        { type: String, default: 'percentage' }, // percentage | fixed
  value:       { type: Number, required: true }, // % off, or NIS off
  active:      { type: Boolean, default: true },
  expiresAt:   { type: Date, default: null }, // null = no expiry
  maxUses:     { type: Number, default: 0 }, // 0 = unlimited
  usedCount:   { type: Number, default: 0 },
  minBookingAmount: { type: Number, default: 0 },
  redeemedBy:  [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: true });
module.exports = mongoose.model('PromoCode', promoSchema);
