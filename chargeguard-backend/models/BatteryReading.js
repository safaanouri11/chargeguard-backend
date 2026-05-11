// Time-series of the user's battery percentage. One row per reading,
// emitted whenever we know the SoC: charging start/stop, manual sync,
// or auto-tracked. Used by the Battery Health screen to chart the
// effective max range and degradation over time.

const mongoose = require('mongoose');
const batteryReadingSchema = new mongoose.Schema({
  user:       { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  batteryPct: { type: Number, required: true },     // 0–100
  source:     { type: String, default: 'manual' },  // manual | charge_start | charge_stop | auto
  // Optional: when paired with a charge event, what kWh was added since the last
  // reading at this user — lets the analytics screen estimate effective capacity.
  kwhDelta:   { type: Number, default: null },
  station:    { type: mongoose.Schema.Types.ObjectId, ref: 'Station', default: null },
  recordedAt: { type: Date,   default: Date.now,    index: true },
}, { timestamps: true });
module.exports = mongoose.model('BatteryReading', batteryReadingSchema);
