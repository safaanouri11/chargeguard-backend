const mongoose = require('mongoose');
const reviewSchema = new mongoose.Schema({
  user:    { type: mongoose.Schema.Types.ObjectId, ref: 'User',    required: true },
  station: { type: mongoose.Schema.Types.ObjectId, ref: 'Station', required: true },
  host:    { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  rating:  { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, default: '' },
}, { timestamps: true });
module.exports = mongoose.model('Review', reviewSchema);