const mongoose = require('mongoose');
const claimSchema = new mongoose.Schema({
  user:  { type: mongoose.Schema.Types.ObjectId, ref: 'User',  required: true },
  offer: { type: mongoose.Schema.Types.ObjectId, ref: 'Offer', required: true },
}, { timestamps: true });
module.exports = mongoose.model('Claim', claimSchema);