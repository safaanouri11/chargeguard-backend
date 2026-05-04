const mongoose = require('mongoose');
const bookingSchema = new mongoose.Schema({
  user:    { type: mongoose.Schema.Types.ObjectId, ref: 'User',    required: true },
  station: { type: mongoose.Schema.Types.ObjectId, ref: 'Station', required: true },
  date:    { type: String, required: true },
  time:    { type: String, required: true },
  status:  { type: String, default: 'Upcoming' },
  price:   { type: Number, default: 5 },
}, { timestamps: true });
module.exports = mongoose.model('Booking', bookingSchema);