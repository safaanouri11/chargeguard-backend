const mongoose = require('mongoose');
const cardSchema = new mongoose.Schema({
  user:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type:      { type: String, default: 'Visa' },
  number:    { type: String, required: true },
  holder:    { type: String, required: true },
  expiry:    { type: String, required: true },
  icon:      { type: String, default: 'VISA' },
  color1:    { type: Number, default: 0xFF1A1F71 },
  color2:    { type: Number, default: 0xFF2563EB },
  isDefault: { type: Boolean, default: false },
}, { timestamps: true });
module.exports = mongoose.model('Card', cardSchema);