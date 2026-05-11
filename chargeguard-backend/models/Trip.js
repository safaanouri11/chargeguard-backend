const mongoose = require('mongoose');
const tripSchema = new mongoose.Schema({
  user:           { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  station:        { type: mongoose.Schema.Types.ObjectId, ref: 'Station', default: null },
  startBatteryPct:{ type: Number, default: 0 },
  endBatteryPct:  { type: Number, default: 0 },
  kwhCharged:     { type: Number, default: 0 },
  cost:           { type: Number, default: 0 },
  durationMin:    { type: Number, default: 0 },   // minutes
  distanceKm:     { type: Number, default: 0 },   // optional, if start location is known
  startLat:       { type: Number, default: null },
  startLng:       { type: Number, default: null },
  endLat:         { type: Number, default: null },
  endLng:         { type: Number, default: null },
  startedAt:      { type: Date, default: Date.now },
  endedAt:        { type: Date, default: Date.now },
}, { timestamps: true });
module.exports = mongoose.model('Trip', tripSchema);
