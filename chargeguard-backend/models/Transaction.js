const mongoose = require('mongoose');
const transactionSchema = new mongoose.Schema({
  user:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  label:  { type: String, required: true },
  amount: { type: Number, required: true },   // positive = credit, negative = debit
  type:   { type: String, enum: ['charge','booking','refund','reward','topup','transfer'], default: 'charge' },
}, { timestamps: true });
module.exports = mongoose.model('Transaction', transactionSchema);