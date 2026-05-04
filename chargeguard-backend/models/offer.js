const mongoose = require('mongoose');
const offerSchema = new mongoose.Schema({
  title:    { type: String, required: true },
  sub:      { type: String, required: true },
  code:     { type: String, required: true },
  discount: { type: String, required: true },
  expires:  { type: String, default: 'No expiry' },
  color:    { type: Number, default: 0xFF00E5A0 },
  type:     { type: String, default: 'promo' },
  badge:    { type: String, default: '' },
  active:   { type: Boolean, default: true },
}, { timestamps: true });
module.exports = mongoose.model('Offer', offerSchema);