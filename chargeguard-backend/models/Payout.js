const mongoose = require('mongoose');
const payoutSchema = new mongoose.Schema({
  host:       { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount:     { type: Number, required: true },
  status:     { type: String, default: 'Pending' }, // Pending, Paid, Rejected
  bankName:   { type: String, default: '' },
  iban:       { type: String, default: '' },
}, { timestamps: true });
module.exports = mongoose.model('Payout', payoutSchema);