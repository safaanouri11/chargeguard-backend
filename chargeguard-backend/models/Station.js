const mongoose = require('mongoose');
const stationSchema = new mongoose.Schema({
  host:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  name:      { type: String, required: true },
  location:  { lat: Number, lng: Number, address: String },
  power:     { type: String, default: '22 kW' },
  connector: { type: String, default: 'CCS2' },
  price:     { type: Number, default: 2.5 },
  available: { type: Boolean, default: true },
  rating:    { type: Number, default: 5.0 },
  status:    { type: String, default: 'Active' },    // Active | Coming Soon
  network:   { type: String, default: 'Independent' }, // ChargePoint, EVgo, Tesla, etc.
  amenities: [{ type: String }],
  parking:   [{ type: String }],
  plugCount: { type: Number, default: 1 },
  vehicles:  [{ type: String }],
}, { timestamps: true });
module.exports = mongoose.model('Station', stationSchema);