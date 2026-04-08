const mongoose = require('mongoose');
const stationSchema = new mongoose.Schema({
  name:      { type: String, required: true },
  host:      { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  location: {
    lat:     { type: Number, required: true },
    lng:     { type: Number, required: true },
    address: { type: String, default: '' },
  },
  power:     { type: String, default: '22 kW' },
  connector: { type: String, default: 'CCS2' },
  price:     { type: Number, default: 2.5 },   // NIS per kWh
  available: { type: Boolean, default: true },
  rating:    { type: Number, default: 5.0 },
}, { timestamps: true });
module.exports = mongoose.model('Station', stationSchema);